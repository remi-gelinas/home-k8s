#!/usr/bin/env python

import subprocess
import json
import sys
import pathlib
import re
import difflib
import operator
from functools import reduce
from ruamel.yaml import YAML
from ruamel.yaml.compat import StringIO
from constants import libDir


class MyYAML(YAML):
    def dump(self, data, stream=None, **kw):
        inefficient = False
        if stream is None:
            inefficient = True
            stream = StringIO()
        YAML.dump(self, data, stream, **kw)
        if inefficient:
            return stream.getvalue()


yaml = MyYAML()
yaml.indent(mapping=2, sequence=4, offset=2)


def find_helm_releases(nested):
    for key, value in nested.items():
        if isinstance(value, dict):
            if "kind" in value and value["kind"] == "HelmRelease":
                yield value

            yield from find_helm_releases(value)


HELM_CHART_VAR_REGEX = re.compile(
    r"renovate: helmChartVar registryUrl=(.*?) chart=(.*?)\n.*['\"](.*?)['\"]"
)
RESOURCE_FILE_REGEX = re.compile(r"^# Source: (.+)$", flags=re.MULTILINE)

jsonnetCommand = ["jsonnet", "-J", libDir]

IGNORED_PATHS = [
    "metadata#labels#helm.sh/chart",
    "metadata#labels#chart",
    "metadata#labels#app.kubernetes.io/version",
    "spec#template#metadata#labels#helm.sh/chart",
    "spec#template#metadata#labels#chart",
    "spec#template#metadata#labels#app.kubernetes.io/version",
]


def get_releases(file):
    fileContent = file.read_text()

    result = subprocess.run([*jsonnetCommand, file], stdout=subprocess.PIPE)
    compiledJsonnet = json.loads(result.stdout)

    # Find all helm releases
    releases = list(find_helm_releases(compiledJsonnet))

    # Find all helm chart variables
    chartVarMatches = list(HELM_CHART_VAR_REGEX.finditer(fileContent))

    # Match all chart variables to helm releases
    helmReleases = {}

    for match in chartVarMatches:
        repo, chart, version = match.groups()

        # Find the helm release that matches the chart variable
        for release in releases:
            if (
                release["spec"]["chart"]["spec"]["chart"] == chart
                and release["spec"]["chart"]["spec"]["version"] == version
            ):
                helmReleases[chart] = {
                    "repo": repo,
                    "chart": chart,
                    "version": version,
                    "release": release,
                }

    return helmReleases


def add_helm_repo(name, repo):
    subprocess.run([sys.argv[3], "repo", "add", name, repo], stdout=subprocess.DEVNULL)


def template_helm_release(chart, repo, version, values=None):
    result = subprocess.run(
        [sys.argv[3], "template", chart, f"{repo}/{chart}", "--version", version],
        stdout=subprocess.PIPE,
    )

    return result.stdout


def remove(element, json):
    keys = element.split("#")
    lastKeyIndex = len(keys) - 1
    rv = json
    lastKey = None

    for i, key in enumerate(keys):
        if key in rv:
            lastKey = key

            if i == lastKeyIndex:
                del rv[key]
                return
            else:
                rv = rv[key]
        else:
            return


def patch_resource_objects(objs):
    for obj in objs:
        for path in IGNORED_PATHS:
            remove(path, obj)


def format_resources(resources):
    formatted = {}

    sources = RESOURCE_FILE_REGEX.findall(resources)
    yaml_objs = list(yaml.load_all(resources))
    patch_resource_objects(yaml_objs)

    for source, obj in zip(sources, yaml_objs):
        if source not in formatted:
            formatted[source] = [obj]
        else:
            formatted[source].append(obj)

    return formatted


def diff_resources_by_source(resources_by_source):
    diffs_by_source = {}

    for source, resources in resources_by_source.items():
        old_yaml = [line + "\n" for line in yaml.dump(resources[0]).splitlines()]
        new_yaml = [line + "\n" for line in yaml.dump(resources[1]).splitlines()]

        diffs_by_source[source] = list(
            difflib.unified_diff(
                old_yaml, new_yaml, fromfile=source, tofile=source, lineterm="\n"
            )
        )

    return {source: "".join(diff) for source, diff in diffs_by_source.items()}


def diff_release(release):
    chart = release["chart"]

    old = release["old"]
    new = release["new"]

    add_helm_repo("old", old["repo"])
    add_helm_repo("new", new["repo"])

    old_resources_string = template_helm_release(chart, "old", old["version"]).decode(
        "utf-8"
    )
    new_resources_string = template_helm_release(chart, "new", new["version"]).decode(
        "utf-8"
    )

    old_resources_by_source = format_resources(old_resources_string)
    new_resources_by_source = format_resources(new_resources_string)

    resources_by_source = {
        source: [*old_resources_by_source[source], *new_resources_by_source[source]]
        for source, objs in old_resources_by_source.items()
        if source in new_resources_by_source
    }

    source_diffs = diff_resources_by_source(resources_by_source)

    return "".join(source_diffs.values())


if __name__ == "__main__":
    oldFile = pathlib.Path(sys.argv[1])
    oldReleases = get_releases(oldFile)

    newFile = pathlib.Path(sys.argv[2])
    newReleases = get_releases(newFile)

    # Isolate matching charts with differing versions
    differentReleases = {
        chartKey: {
            "chart": chart["chart"],
            "old": {
                "repo": oldReleases[chartKey]["repo"],
                "version": oldReleases[chartKey]["version"],
                "release": oldReleases[chartKey]["release"],
            },
            "new": {
                "repo": newReleases[chartKey]["repo"],
                "version": newReleases[chartKey]["version"],
                "release": newReleases[chartKey]["release"],
            },
        }
        for chartKey, chart in oldReleases.items()
        if chartKey in newReleases
        and (
            chart["version"] != newReleases[chartKey]["version"]
            or chart["repo"] != newReleases[chartKey]["repo"]
        )
    }

    for chartKey, release in differentReleases.items():
        message = f"Path: `{oldFile}`"

        if release["old"]["version"] != release["new"]["version"]:
            message = (
                message
                + f"\nVersion: `{release['old']['version']}` -> `{release['new']['version']}`"
            )

        if release["old"]["repo"] != release["new"]["repo"]:
            message = (
                message
                + f"\nRepo: `{release['old']['repo']}` -> `{release['new']['repo']}`"
            )

        diff = diff_release(release)

        if diff != "":
            message = message + f"\n```diff\n{diff}\n```"
        else:
            message = message + f"\n```No changes detected in resources```"

        print(message)
