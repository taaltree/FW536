#!/usr/bin/env python3
"""Build the student R project, FW536_R_project.zip, from the course repo.

Students get one download holding every dataset, R script, and R Markdown
template, organised by day, plus an RStudio project file and a package
installer. Every data read in the course uses here::here("DayN_...", "data",
"file.csv"), which finds the file from the project root whether the code is run
in the Console, from a script, or while knitting a template.

    python3 _tools/build_student_project.py           # rebuild the zip
    python3 _tools/build_student_project.py --check   # exit 1 if the zip is stale
                                                      # or any here::here() path is broken

Run it after editing any dataset, R script, or template, then commit the zip.
The zip is byte-for-byte reproducible (sorted entries, fixed timestamps), so
--check can compare it exactly and git only sees a change when content changed.

What goes in: every Day*/data/ file, every Day*/*_lab_template.Rmd, every Day*/*.R,
and rmarkdown_tutorial_starter.Rmd, minus EXCLUDE below. What is generated:
FW536.Rproj, 00_install_packages.R (the package list is read from the code
itself, so it cannot drift), and README.txt.
"""
import argparse
import glob
import html
import io
import os
import re
import sys
import zipfile

ZIP_NAME = "FW536_R_project.zip"
TOP = "FW536_R_project"

# Not shipped: the two JAGS comparison files (the course fits every model in
# Nimble; lizzard.R is a BUGS model, not R code, so it cannot be run in R) and two
# legacy .dat copies of data that ship as .csv and are read by nothing.
EXCLUDE = {
    "Day4_Likelihood_BayesI/Jags_logistic_rK_Lab1.R",
    "Day5_BayesII/lizzard.R",
    "Day4_Likelihood_BayesI/data/Vonbert.dat",
    "Day4_Likelihood_BayesI/data/Whale.dat",
}
ROOT_FILES = ["rmarkdown_tutorial_starter.Rmd"]

BASE_PKGS = {"base", "stats", "stats4", "graphics", "grDevices", "utils", "methods",
             "parallel", "splines", "tools", "grid", "tcltk", "compiler", "datasets"}
SKIP_PKGS = {"rjags", "R2jags", "jagsUI"}          # JAGS is optional and not used
ALWAYS_PKGS = {"here", "rmarkdown", "knitr"}

RPROJ = """Version: 1.0

RestoreWorkspace: No
SaveWorkspace: No
AlwaysSaveHistory: Default

EnableCodeIndexing: Yes
UseSpacesForTab: Yes
NumSpacesForTab: 2
Encoding: UTF-8

RnwWeave: Sweave
LaTeX: pdfLaTeX
"""

README = """FW 536 · Statistical Modeling for Ecology and Conservation
Course R project
============================================================

1. Unzip this folder anywhere on your computer (not inside another zip viewer).
2. Double-click FW536.Rproj. RStudio opens with this folder as the project.
3. Run this once in the RStudio Console to install the course packages:

       source("00_install_packages.R")

   Nimble also needs a C++ compiler. See the setup guide:
   https://taaltree.github.io/FW536/install_jags_nimble.html

Each day has its own folder:

   DayN_.../data/                  the datasets for that day
   DayN_.../*_lab_template.Rmd     the R Markdown hand-in templates
   DayN_.../*.R                    the R scripts used in the labs

All course code finds data with here::here(), for example

   read.csv(here::here("Day4_Likelihood_BayesI", "data", "vonbert.csv"))

That works from the Console, from a script, and when you knit a template, as
long as you opened FW536.Rproj first. Do not rename the day folders or move
the data files.

Course website: https://taaltree.github.io/FW536/
"""

PKG_RE = re.compile(r"\b(?:library|require|requireNamespace)\(\s*[\"']?([A-Za-z][A-Za-z0-9.]*)[\"']?"
                    r"|\b([A-Za-z][A-Za-z0-9.]*)::")
HERE_RE = re.compile(r'here::here\(((?:\s*"[^"]*"\s*,?)+)\)')


def root_dir():
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def course_files():
    files = []
    for day in sorted(glob.glob("Day*")):
        if not os.path.isdir(day):
            continue
        files += sorted(f for f in glob.glob(os.path.join(day, "data", "*")) if os.path.isfile(f))
        files += sorted(glob.glob(os.path.join(day, "*_lab_template.Rmd")))
        files += sorted(glob.glob(os.path.join(day, "*.R")))
    files += [f for f in ROOT_FILES if os.path.exists(f)]
    return [f for f in files if f not in EXCLUDE]


def strip_r_comments(text):
    return "\n".join(line.split("#", 1)[0] for line in text.splitlines())


def html_code(text):
    """R code shown on the site: <pre><code> blocks, tags removed, entities decoded."""
    blocks = re.findall(r"<pre><code>(.*?)</code></pre>", text, re.S)
    return "\n".join(html.unescape(re.sub(r"<[^>]+>", "", b)) for b in blocks)


def packages(bundled):
    sources = [strip_r_comments(open(f, encoding="utf-8").read())
               for f in bundled if f.endswith((".R", ".Rmd"))]
    for page in sorted(glob.glob("Day*/lab.html") + glob.glob("Day*/problem_set.html")):
        sources.append(strip_r_comments(html_code(open(page, encoding="utf-8").read())))
    found = set(ALWAYS_PKGS)
    for src in sources:
        for m in PKG_RE.finditer(src):
            found.add(m.group(1) or m.group(2))
    return sorted(found - BASE_PKGS - SKIP_PKGS, key=str.lower)


def install_script(pkgs):
    quoted = ",\n  ".join(", ".join(f'"{p}"' for p in pkgs[i:i + 6]) for i in range(0, len(pkgs), 6))
    return f"""# FW 536: install every R package the course uses.
# Run once, with FW536.Rproj open:   source("00_install_packages.R")
#
# Nimble also needs a C++ compiler (Rtools on Windows, Xcode Command Line Tools
# on Mac). See https://taaltree.github.io/FW536/install_jags_nimble.html
#
# This file is generated from the course code by _tools/build_student_project.py.

pkgs <- c(
  {quoted}
)

missing <- setdiff(pkgs, rownames(installed.packages()))
if (length(missing) == 0) {{
  message("All ", length(pkgs), " course packages are already installed.")
}} else {{
  message("Installing ", length(missing), " package(s): ", paste(missing, collapse = ", "))
  install.packages(missing)
}}

still_missing <- setdiff(pkgs, rownames(installed.packages()))
if (length(still_missing) > 0) {{
  warning("These packages did not install: ", paste(still_missing, collapse = ", "),
          ". See the setup guide's troubleshooting section.")
}} else {{
  message("Done. Every course package is installed.")
}}
"""


def build_zip(bundled, pkgs):
    buf = io.BytesIO()
    entries = [(f, open(f, "rb").read()) for f in bundled]
    entries += [("FW536.Rproj", RPROJ.encode()), ("00_install_packages.R", install_script(pkgs).encode()),
                ("README.txt", README.encode())]
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as z:
        for name, data in sorted(entries):
            info = zipfile.ZipInfo(f"{TOP}/{name}", date_time=(2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            z.writestr(info, data)
    return buf.getvalue()


def broken_here_paths():
    """Every here::here("a", "b", ...) in the course must name a file that exists."""
    problems = []
    targets = glob.glob("Day*/*.html") + glob.glob("Day*/*.Rmd") + glob.glob("Day*/*.R")
    for f in sorted(targets):
        text = open(f, encoding="utf-8").read()
        if f.endswith(".html"):
            text = html.unescape(re.sub(r"<[^>]+>", "", text))
        for m in HERE_RE.finditer(text):
            parts = re.findall(r'"([^"]*)"', m.group(1))
            path = os.path.join(*parts) if parts else ""
            if parts and not os.path.exists(path):
                problems.append(f"{f}: here::here() points to missing {path}")
    return sorted(set(problems))


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--check", action="store_true", help="write nothing; exit 1 if stale or broken")
    args = ap.parse_args()
    os.chdir(root_dir())

    bundled = course_files()
    pkgs = packages(bundled)
    data = build_zip(bundled, pkgs)
    broken = broken_here_paths()
    for b in broken:
        print("  BROKEN  " + b)

    current = open(ZIP_NAME, "rb").read() if os.path.exists(ZIP_NAME) else None
    if args.check:
        stale = current != data
        print(f"  {ZIP_NAME}: {'out of date, run python3 _tools/build_student_project.py' if stale else 'up to date'}")
        return 1 if (stale or broken) else 0

    if current != data:
        open(ZIP_NAME, "wb").write(data)
        print(f"  wrote {ZIP_NAME}: {len(bundled) + 3} files, {len(data) / 1024:.0f} KB")
    else:
        print(f"  {ZIP_NAME} already up to date")
    print(f"  packages ({len(pkgs)}): {', '.join(pkgs)}")
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main())
