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
PROGRAMS = {"elixir": "*.exs"}
RUNNERS = {"elixir": "elixir"}
FIXTURE_SUFFIX = ".trace"
NEEDS_DEPS = "# needs: deps"
TIMEOUT_SECONDS = 120
COLOURLESS = {"NO_COLOR": "1", "FORCE_COLOR": "0", "PYTHON_COLORS": "0"}

TIMESTAMP = re.compile(r"^\d\d:\d\d:\d\d\.\d{3} ", re.M)
FILE_URL = "file://"
# Machine paths only: a route such as /ch07/notes/1 is course output.
FILESYSTEM_ROOTS = ("/" + "Users/", "/" + "home/", "/private/", "/var/folders/", "/tmp/")
# LiveView's ids are 16 url-safe base64 characters; phx- attributes are lower case.
LIVEVIEW_ID = re.compile(r"(?<![\w-])phx-(?=[\w-]{0,15}[A-Z0-9])[\w-]{16}(?![\w-])", re.ASCII)
RUNTIME_APPS = "stdlib|kernel|elixir|mix|ex_unit|logger|compiler|iex"
RUNTIME_FRAME = re.compile(
    rf"^\s+(\((?:{RUNTIME_APPS})(?: [^)]*)?\) |at .*\bnode:internal/)"
)
RUNTIME_PLACEHOLDER = "    <runtime frames>"
MASK = [
    (re.compile(r"^Node\.js v[\d.]+$", re.M), "Node.js v_"),
    (re.compile(r"#PID<[\d.]+>"), "#PID<_>"),
    (re.compile(r"#Reference<[\d.]+>"), "#Reference<_>"),
    (re.compile(r"#Port<[\d.]+>"), "#Port<_>"),
    (LIVEVIEW_ID, "phx-_"),
]


def scrub(text: str, root: Path) -> str:
    for base in [*(root / track for track in DIALECTS), root]:
        text = text.replace(f"file://{base}/", "").replace(f"{base}/", "")
    return TIMESTAMP.sub("", text)


def mask(text: str) -> str:
    for pattern, replacement in MASK:
        text = pattern.sub(replacement, text)
    lines: list[str] = []
    for line in text.splitlines():
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
    if "warning:" in text:
        return "warning:"
    return None


def run(track: str, program: Path) -> str:
    program = program.resolve()
    cwd = program.parent.parent
    env = {**os.environ, **COLOURLESS}
    if needs_deps(program):
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
    with program.open() as source:
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
    refused = 0
    for program in programs:
        output = run(track, program)
        reason = refusal(output)
        if reason:
            print(f"refused {program.name}: {reason} in the output", file=sys.stderr)
            refused += 1
        else:
            fixture_for(program).write_text(output)
    return 1 if refused else 0


def check(track: str, programs: list[Path]) -> int:
    missing = [p.name for p in programs if not fixture_for(p).is_file()]
    stale = [
        p.name
        for p in programs
        if fixture_for(p).is_file() and mask(run(track, p)) != mask(fixture_for(p).read_text())
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
