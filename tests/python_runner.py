"""Runs pytest on the Python track in a subprocess, reads its KOANS-TEST lines, and stages variants under _variants/."""

import fcntl
import os
import re
import shutil
import subprocess
import sys
from collections.abc import Mapping
from dataclasses import dataclass
from pathlib import Path

from elixir_runner import RESULT_LINE, STAGE_NAME, TEST_LINE, KoansResult
from harness import ROOT

PYTHON_DIR = ROOT / "python"
VARIANTS = PYTHON_DIR / "_variants"
VARIANT_KEY = re.compile(r"v\d{4}")
QUIET = {"NO_COLOR": "1", "PYTHON_COLORS": "0", "PYTHONDONTWRITEBYTECODE": "1"}


@dataclass(frozen=True)
class PytestRun:
    returncode: int
    output: str
    results: dict[tuple[str, int], str]


def run_pytest(args: list[str], *, verify: bool = False, timeout: int = 900) -> PytestRun:
    env = {**os.environ, **QUIET}
    env.pop("KOANS_VERIFY", None)
    if verify:
        env["KOANS_VERIFY"] = "1"
    done = subprocess.run(
        [sys.executable, "-m", "pytest", "--color=no", *args],
        cwd=PYTHON_DIR,
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        timeout=timeout,
    )
    results = {(m["path"], int(m["line"])): m["kind"] for m in TEST_LINE.finditer(done.stdout)}
    return PytestRun(done.returncode, done.stdout, results)


def koans_result(run: PytestRun) -> KoansResult | None:
    """The KOANS-RESULT line: the earliest failure at its blank's own line, or kind `ok`."""
    match = RESULT_LINE.search(run.output)
    if match is None:
        return None
    line = int(match["line"]) if match["line"] else None
    return KoansResult(match["kind"], match["path"], line)


def _plain_name(name: str) -> str:
    if Path(name).name != name or name.startswith("."):
        raise ValueError(f"staged file names are plain names, not {name!r}")
    return name


def _fresh(name: str) -> Path:
    if not STAGE_NAME.fullmatch(name):
        raise ValueError(f"stage names are lower-case words, not {name!r}")
    target = VARIANTS / name
    if target.exists():
        shutil.rmtree(target)
    target.mkdir(parents=True)
    return target


def _write_tree(target: Path, tests: Mapping[str, str], reviews: Mapping[str, str]) -> None:
    (target / "review").mkdir(parents=True)
    for file, text in tests.items():
        (target / _plain_name(file)).write_text(text, encoding="utf-8")
    for file, text in reviews.items():
        (target / "review" / _plain_name(file)).write_text(text, encoding="utf-8")


def stage_each(name: str, variants: Mapping[str, tuple[Mapping[str, str], Mapping[str, str]]]) -> str:
    """Recreates _variants/<name>/ with one vNNNN/ folder per variant, each holding its tests and review/."""
    target = _fresh(name)
    for key, (tests, reviews) in variants.items():
        if not VARIANT_KEY.fullmatch(key):
            raise ValueError(f"variant folders are named v0001 and up, not {key!r}")
        _write_tree(target / key, tests, reviews)
    return f"_variants/{name}"


def run_staged(name: str, variants: Mapping[str, tuple[Mapping[str, str], Mapping[str, str]]]) -> PytestRun:
    """Stages the variants and runs them in verify mode, holding _variants/.lock so concurrent runs take turns."""
    VARIANTS.mkdir(exist_ok=True)
    with (VARIANTS / ".lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            return run_pytest([stage_each(name, variants)], verify=True)
        finally:
            fcntl.flock(lock, fcntl.LOCK_UN)
