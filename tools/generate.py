"""Generate <track>/koans and <track>/solutions from <track>/source.

Usage: python tools/generate.py [--check] [track ...]
"""

import argparse
import re
import sys
from pathlib import Path

from dialects import DIALECTS, Dialect, dialect_for

ROOT = Path(__file__).resolve().parent.parent
VALUE_MARKER = re.compile(r"(?<![A-Za-z0-9_?!@.])_a\(")
BLOCK_OPEN = "# >>> "
BLOCK_CLOSE = "# <<<"
ANSWER_TAG = "answer"
TREES = ("koans", "solutions")


class GenerationError(Exception):
    pass


def _line_of(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def render_values(path: str, text: str, dialect: Dialect, *, solved: bool) -> str:
    out = []
    pos = 0
    while match := VALUE_MARKER.search(text, pos):
        line = _line_of(text, match.start())
        try:
            end = dialect.find_value_end(text, match.end())
        except ValueError as error:
            raise GenerationError(f"{path}:{line}: {error}") from None
        inner = text[match.end() : end]
        if VALUE_MARKER.search(inner):
            raise GenerationError(f"{path}:{line}: nested _a(")
        out.append(text[pos : match.start()])
        out.append(inner if solved else dialect.value_blank)
        pos = end + 1
    out.append(text[pos:])
    return "".join(out)


def render_code_blocks(path: str, text: str, dialect: Dialect, *, solved: bool) -> str:
    out = []
    open_tag = None
    open_line = 0
    for number, line in enumerate(text.splitlines(keepends=True), 1):
        stripped = line.strip()
        if stripped.startswith(BLOCK_OPEN) and open_tag is None:
            open_tag, open_line = stripped[len(BLOCK_OPEN) :].strip(), number
            if open_tag == ANSWER_TAG:
                if not solved:
                    indent = line[: len(line) - len(line.lstrip())]
                    out.append(f"{indent}{dialect.code_blank('')}\n")
            else:
                out.append(line)
        elif stripped.startswith(BLOCK_OPEN):
            raise GenerationError(f"{path}:{number}: nested {BLOCK_OPEN.strip()} inside line {open_line}")
        elif stripped == BLOCK_CLOSE:
            if open_tag is None:
                raise GenerationError(f"{path}:{number}: {BLOCK_CLOSE} without {BLOCK_OPEN.strip()}")
            if open_tag != ANSWER_TAG:
                out.append(line)
            open_tag = None
        elif open_tag == ANSWER_TAG and not solved:
            continue
        else:
            out.append(line)
    if open_tag is not None:
        raise GenerationError(f"{path}:{open_line}: unclosed {BLOCK_OPEN}{open_tag}")
    return "".join(out)


def _render(path: str, text: str, dialect: Dialect, *, solved: bool) -> str:
    render_values(path, text, dialect, solved=solved)
    blocks = render_code_blocks(path, text, dialect, solved=solved)
    return render_values(path, blocks, dialect, solved=solved)


def _relative(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def render_track(track: str, root: Path = ROOT) -> dict[Path, str]:
    dialect = dialect_for(track)
    base = root / track
    outputs = {}
    for source in sorted((base / "source").rglob("*")):
        if not source.is_file():
            continue
        relative = source.relative_to(base / "source")
        shown = _relative(source, root)
        text = source.read_text()
        for tree in TREES:
            outputs[base / tree / relative] = _render(shown, text, dialect, solved=tree == "solutions")
    return outputs


def _existing(track: str, root: Path) -> set[Path]:
    return {
        path
        for tree in TREES
        for path in (root / track / tree).rglob("*")
        if path.is_file()
    }


def _problems(track: str, root: Path, outputs: dict[Path, str]) -> list[str]:
    problems = []
    for path, content in outputs.items():
        if not path.exists():
            problems.append(f"missing: {_relative(path, root)}")
        elif path.read_text() != content:
            problems.append(f"stale: {_relative(path, root)}")
    problems.extend(f"orphan: {_relative(p, root)}" for p in sorted(_existing(track, root) - outputs.keys()))
    return problems


def _write(track: str, root: Path, outputs: dict[Path, str]) -> None:
    for path, content in outputs.items():
        if not path.exists() or path.read_text() != content:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
    for orphan in _existing(track, root) - outputs.keys():
        orphan.unlink()


def main(argv: list[str] | None = None, root: Path = ROOT) -> int:
    parser = argparse.ArgumentParser(prog="generate.py")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("tracks", nargs="*")
    args = parser.parse_args(argv)
    tracks = args.tracks or [name for name in DIALECTS if (root / name).is_dir()]
    failed = False
    for track in tracks:
        try:
            outputs = render_track(track, root)
        except (GenerationError, KeyError) as error:
            print(error.args[0] if isinstance(error, KeyError) else error, file=sys.stderr)
            return 1
        if args.check:
            problems = _problems(track, root, outputs)
            if problems:
                failed = True
                print("\n".join([*problems, f"run: python tools/generate.py {track}"]))
        else:
            _write(track, root, outputs)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
