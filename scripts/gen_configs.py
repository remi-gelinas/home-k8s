#!/usr/local/bin/python

import os
import subprocess
import json
import yaml
import pathlib


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
            yaml.dump(content),
        )
        for (fileName, content) in json.items()
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


repoRoot = pathlib.Path(__file__).parent.parent.resolve()

baseDir = repoRoot / "kubernetes" / "config"
outDir = repoRoot / "kubernetes" / "_gen"
libDir = repoRoot / "kubernetes" / "config" / "lib"


def cleanOutDir():
    subprocess.run(
        [
            'rm',
            '-rf',
            outDir,
        ],
        shell=True
    )


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

        if not os.path.exists(path):
            os.makedirs(path)

        with file.open("w") as manifest:
            manifest.write("---\n")
            manifest.write(content)

    if "HOOK_MODE" in os.environ:
        subprocess.run(["git", "add", outDir.relative_to(repoRoot)], cwd=repoRoot)

except Exception as e:
    cleanOutDir()
    raise e
