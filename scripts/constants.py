import pathlib

repoRoot = pathlib.Path(__file__).parent.parent.resolve()

baseDir = repoRoot / "kubernetes" / "config"
outDir = repoRoot / "kubernetes" / "_gen"
libDir = repoRoot / "kubernetes" / "config" / "lib"
