#!/usr/local/bin/python

import subprocess
import json
from ruamel.yaml import YAML
import pathlib
import shutil
import re
from constants import repoRoot, outDir, baseDir, libDir

yaml = YAML()
yaml.indent(mapping=2, sequence=4, offset=2)


def replacePaths(inPath, outPath):
    # If the second part doesn't match, don't bother
    if inPath.parts[1] != outPath.parts[1]:
        return inPath

    # If the first part matches, check the rest
    for index, part in enumerate(inPath.parts):
        if inPath.parts[index] != outPath.parts[index]:
            nextIndex = index + 1

            return (
                pathlib.Path()
                .joinpath(*outPath.parts[:nextIndex])
                .joinpath(*inPath.parts[nextIndex:])
            )


def genSentinelExists(filePath):
    with filePath.open("r") as manifest:
        return re.match(r"^#\s*skip-gen\s*$", manifest.readline())


def getManifests(files, extract):
    return [
        manifest
        for manifestList in [
            extract(
                filePath,
                json.loads(subprocess.check_output(jsonnetCommand + [filePath])),
            )
            for filePath in files
        ]
        for manifest in manifestList
    ]


def extractMulti(filePath, json):
    base = pathlib.Path().joinpath(*filePath.parts[:-1])
    fileName = filePath.parts[-1]

    return [
        (
            replacePaths(pathlib.Path() / base / f"{fileName}.yaml", outDir),
            content,
        )
        for (fileName, content) in json.items()
        if not genSentinelExists(filePath)
    ]


def extractSingle(filePath, json):
    base = pathlib.Path().joinpath(*filePath.parts[:-1])
    fileName = filePath.stem

    return [
        (
            replacePaths(pathlib.Path() / base / f"{fileName}.yaml", outDir),
            yaml.dump(json),
        )
    ]


def cleanOutDir():
    if outDir.exists():
        shutil.rmtree(outDir, ignore_errors=True)


jsonnetCommand = ["jsonnet", "-J", libDir]

jsonnetMultiFiles, jsonnetFiles = [], []
for filePath in baseDir.glob("**/*.jsonnet"):
    jsonnetMultiFiles.append(filePath) if filePath.match(
        "*.multi.jsonnet"
    ) else jsonnetFiles.append(filePath)

try:
    cleanOutDir()

    manifests = getManifests(jsonnetMultiFiles, extractMulti) + getManifests(
        jsonnetFiles, extractSingle
    )

    for file, content in manifests:
        path = pathlib.Path().joinpath(*file.parts[:-1])

        if not path.exists():
            path.mkdir(parents=True)

        with file.open("w") as manifest:
            with YAML(output=manifest) as yaml:
                manifest.write("# GENERATED - DO NOT EDIT\n")
                manifest.write("---\n")
                yaml.dump(content)

except Exception as e:
    cleanOutDir()
    raise e
