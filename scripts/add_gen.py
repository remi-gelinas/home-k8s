#!/usr/local/bin/python

import pathlib
import subprocess
from constants import repoRoot, outDir

subprocess.run(["git", "add", outDir.relative_to(repoRoot)], cwd=repoRoot)
