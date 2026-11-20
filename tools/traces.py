"""Capture trace programs' crash output into fixtures, and check the fixtures are still current.

Usage: python tools/traces.py capture|check <track> [names...]
"""

import argparse
import functools
import os
import re
import subprocess
import sys
from pathlib import Path

from dialects import DIALECTS, dialect_for

ROOT = Path(__file__).resolve().parent.parent
PROGRAMS = {"elixir": "*.exs", "python": "*.py"}
RUNNERS = {"elixir": "elixir"}
CAPTURE_PYTHON = (3, 13)
FIXTURE_SUFFIX = ".trace"
NEEDS_DEPS = "# needs: deps"
TIMEOUT_SECONDS = 120
COLOURLESS = {"NO_COLOR": "1", "FORCE_COLOR": "0", "PYTHON_COLORS": "0"}

TIMESTAMP = re.compile(r"^\d\d:\d\d:\d\d\.\d{3} ", re.M)
FILE_URL = "file://"
# Machine paths only: a route such as /ch07/notes/1 is course output.
FILESYSTEM_ROOTS = (
    "/" + "Users/", "/" + "home/", "/private/", "/var/folders/", "/tmp/", "/opt/", "/usr/", "/nix/"
)
# A LiveView id holds an upper-case letter; phx- attribute names are lower case or followed by "=".
LIVEVIEW_ID = re.compile(r"(?<![\w-])phx-(?=[\w-]*[A-Z])[\w-]{12,}(?![\w=-])", re.ASCII)
RUNTIME_APPS = "stdlib|kernel|elixir|mix|ex_unit|logger|compiler|iex"
RUNTIME_FRAME = re.compile(
    rf"^\s+(\((?:{RUNTIME_APPS})(?: [^)]*)?\) |at .*\bnode:internal/)"
)
RUNTIME_PLACEHOLDER = "    <runtime frames>"
STDLIB_PATH = re.compile(r'(?<=File ")[^"]*/lib/python3\.\d+t?/')
STDLIB_FRAME = re.compile(r'^(?P<gutter>[ |+-]*)File "<stdlib>/')
PYTHON_PLACEHOLDER = "<runtime frames>"
MASK = [
    (re.compile(r"^Node\.js v[\d.]+$", re.M), "Node.js v_"),
    (re.compile(r"#PID<[\d.]+>"), "#PID<_>"),
    (re.compile(r"#Reference<[\d.]+>"), "#Reference<_>"),
    (re.compile(r"#Port<[\d.]+>"), "#Port<_>"),
    (LIVEVIEW_ID, "phx-_"),
]


def scrub(text: str, root: Path) -> str:
    text = STDLIB_PATH.sub("<stdlib>/", text)
    for base in [*(root / track for track in DIALECTS), root]:
        text = text.replace(f"file://{base}/", "").replace(f"{base}/", "")
    return TIMESTAMP.sub("", text)


def collapse_stdlib_frames(lines: list[str]) -> list[str]:
    kept: list[str] = []
    gutter: str | None = None
    for line in lines:
        found = STDLIB_FRAME.match(line)
        if found:
            gutter = found["gutter"]
            placeholder = gutter + PYTHON_PLACEHOLDER
            if not kept or kept[-1] != placeholder:
                kept.append(placeholder)
        elif gutter is not None and line.startswith(gutter + " "):
            continue
        else:
            gutter = None
            kept.append(line)
    return kept


def mask(text: str) -> str:
    for pattern, replacement in MASK:
        text = pattern.sub(replacement, text)
    lines: list[str] = []
    for line in collapse_stdlib_frames(text.splitlines()):
        if not RUNTIME_FRAME.match(line):
            lines.append(line)
        elif not lines or lines[-1] != RUNTIME_PLACEHOLDER:
            lines.append(RUNTIME_PLACEHOLDER)
    return "\n".join(lines)


def machine_paths() -> re.Pattern[str]:
    roots = [*FILESYSTEM_ROOTS, f"{Path.home()}/", f"{ROOT}/"]
    alternatives = "|".join(re.escape(root) for root in roots)
    return re.compile(rf"{re.escape(FILE_URL)}|(?<![\w./-])(?:{alternatives})", re.ASCII)


def refusal(text: str) -> str | None:
    if machine_paths().search(text):
        return "absolute path"
    if "warning:" in text.lower():
        return "warning:"
    return None


def run(track: str, program: Path) -> str:
    program = program.resolve()
    cwd = program.parent.parent
    env = {**os.environ, **COLOURLESS}
    if track == "python":
        env = {**env, "PYTHONDONTWRITEBYTECODE": "1"}
        command = [sys.executable, f"traces/{program.name}"]
    elif needs_deps(program):
        env = {**env, **solutions_env()}
        compile_solutions(cwd)
        command = ["mix", "run", "--no-compile", f"traces/{program.name}"]
    else:
        command = [RUNNERS[track], f"traces/{program.name}"]
    done = subprocess.run(
        command, cwd=cwd, env=env, capture_output=True, text=True, timeout=TIMEOUT_SECONDS
    )
    output = f"exit {done.returncode}\n--- stdout\n{done.stdout}--- stderr\n{done.stderr}"
    return scrub(output, ROOT)


def needs_deps(program: Path) -> bool:
    with program.open(encoding="utf-8") as source:
        return source.readline().strip() == NEEDS_DEPS


def solutions_env() -> dict[str, str]:
    return {
        "MIX_ENV": "test",
        "KOANS_DIR": "solutions",
        "MIX_BUILD_PATH": str(ROOT / "elixir" / "_build_solutions"),
    }


@functools.cache
def compile_solutions(project: Path) -> None:
    done = subprocess.run(
        ["mix", "compile"],
        cwd=project,
        env={**os.environ, **COLOURLESS, **solutions_env()},
        capture_output=True,
        text=True,
    )
    if done.returncode != 0:
        raise RuntimeError(f"mix compile failed:\n{done.stdout}{done.stderr}")


def fixture_for(program: Path) -> Path:
    return program.with_name(program.name + FIXTURE_SUFFIX)


def traces_dir(track: str) -> Path:
    dialect_for(track)
    if track not in PROGRAMS:
        raise KeyError(f"track {track!r} has no trace programs")
    return ROOT / track / "traces"


def programs_in(track: str) -> list[Path]:
    return sorted(traces_dir(track).glob(PROGRAMS[track]))


def orphans_in(track: str) -> list[str]:
    fixtures = traces_dir(track).glob("*" + FIXTURE_SUFFIX)
    return sorted(f.name for f in fixtures if not f.with_suffix("").is_file())


def select(programs: list[Path], names: list[str]) -> list[Path]:
    if not names:
        return programs
    by_name = {key: p for p in programs for key in (p.name, p.name.split(".")[0])}
    unknown = [name for name in names if name not in by_name]
    if unknown:
        raise KeyError(f"no trace program named {unknown}")
    return [by_name[name] for name in names]


def capture(track: str, programs: list[Path]) -> int:
    if track == "python" and tuple(sys.version_info[:2]) != CAPTURE_PYTHON:
        print(
            "capture python traces on Python 3.13: python3.13 tools/traces.py capture python …",
            file=sys.stderr,
        )
        return 1
    refused = 0
    for program in programs:
        output = run(track, program)
        reason = refusal(output)
        if reason:
            print(f"refused {program.name}: {reason} in the output", file=sys.stderr)
            refused += 1
        else:
            fixture_for(program).write_text(output, encoding="utf-8")
    return 1 if refused else 0


def check(track: str, programs: list[Path]) -> int:
    missing = [p.name for p in programs if not fixture_for(p).is_file()]
    stale = [
        p.name
        for p in programs
        if fixture_for(p).is_file() and mask(run(track, p)) != mask(fixture_for(p).read_text(encoding="utf-8"))
    ]
    problems = {"stale": stale, "missing": missing, "orphan": orphans_in(track)}
    for label, names in problems.items():
        if names:
            print(f"{label}: {names}")
    if not any(problems.values()):
        print("ok")
        return 0
    return 1


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("command", choices=["capture", "check"])
    parser.add_argument("track")
    parser.add_argument("names", nargs="*")
    args = parser.parse_args(argv)
    chosen = select(programs_in(args.track), args.names)
    if args.command == "capture":
        return capture(args.track, chosen)
    return check(args.track, chosen)


if __name__ == "__main__":
    sys.exit(main())
