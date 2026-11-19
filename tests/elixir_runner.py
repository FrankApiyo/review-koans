"""Runs mix in a subprocess, reads its KOANS-TEST lines, and stages variant trees under _variants/."""

import os
import re
import shutil
import subprocess
from collections.abc import Mapping
from dataclasses import dataclass
from pathlib import Path

from harness import ROOT

ELIXIR = ROOT / "elixir"
VARIANTS = ELIXIR / "_variants"
STAGE_NAME = re.compile(r"[a-z][a-z0-9_]*")
TEST_LINE = re.compile(r"^KOANS-TEST (?P<kind>\S+) (?P<path>\S+):(?P<line>\d+)$", re.M)
RESULT_LINE = re.compile(r"^KOANS-RESULT (?P<kind>\S+)(?: (?P<path>\S+):(?P<line>\d+))?$", re.M)
QUIET_OFFLINE = {"MIX_ENV": "test", "HEX_OFFLINE": "1", "NO_COLOR": "1"}


@dataclass(frozen=True)
class MixRun:
    returncode: int
    output: str
    results: dict[tuple[str, int], str]


@dataclass(frozen=True)
class KoansResult:
    kind: str
    path: str | None
    line: int | None


def run_mix(
    args: list[str], *, koans_dir: str, build_path: str, verify: bool = False, timeout: int = 1800
) -> MixRun:
    env = {**os.environ, **QUIET_OFFLINE, "KOANS_DIR": koans_dir, "MIX_BUILD_PATH": str(ELIXIR / build_path)}
    env.pop("KOANS_VERIFY", None)
    if verify:
        env["KOANS_VERIFY"] = "1"
    done = subprocess.run(
        ["mix", *args],
        cwd=ELIXIR,
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        timeout=timeout,
    )
    results = {(m["path"], int(m["line"])): m["kind"] for m in TEST_LINE.finditer(done.stdout)}
    return MixRun(done.returncode, done.stdout, results)


def koans_result(run: MixRun) -> KoansResult | None:
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


def stage(name: str, tests: Mapping[str, str], reviews: Mapping[str, str]) -> str:
    if not STAGE_NAME.fullmatch(name):
        raise ValueError(f"stage names are lower-case words, not {name!r}")
    target = VARIANTS / name
    if target.exists():
        shutil.rmtree(target)
    (target / "review").mkdir(parents=True)
    helper = (ELIXIR / "source" / "test_helper.exs").read_text(encoding="utf-8")
    (target / "test_helper.exs").write_text(helper, encoding="utf-8")
    for file, text in tests.items():
        (target / _plain_name(file)).write_text(text, encoding="utf-8")
    for file, text in reviews.items():
        (target / "review" / _plain_name(file)).write_text(text, encoding="utf-8")
    return f"_variants/{name}"
