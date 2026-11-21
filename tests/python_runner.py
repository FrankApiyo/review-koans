"""Runs pytest on the Python track in a subprocess, reads its KOANS-TEST lines, and stages variants under _variants/."""

import os
import subprocess
import sys
from dataclasses import dataclass

from elixir_runner import RESULT_LINE, TEST_LINE, KoansResult
from harness import ROOT, Variants, stage_variants, variants_locked

PYTHON_DIR = ROOT / "python"
VARIANTS = PYTHON_DIR / "_variants"
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


def stage_each(name: str, variants: Variants) -> str:
    """Recreates _variants/<name>/ with one vNNNN/ folder per variant, each holding its tests and review/."""
    return stage_variants(VARIANTS, name, variants)


def run_staged(name: str, variants: Variants) -> PytestRun:
    """Stages the variants and runs them in verify mode, holding _variants/.lock so concurrent runs take turns."""
    with variants_locked(VARIANTS):
        return run_pytest([stage_each(name, variants)], verify=True)
