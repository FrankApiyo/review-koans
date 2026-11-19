"""Track-neutral helpers for the self-tests: scope, review renders, verdicts and static scans."""

import os
import re
import subprocess
from collections.abc import Iterable
from dataclasses import dataclass
from pathlib import Path
from typing import Literal

import generate
from dialects import dialect_for

ROOT = Path(__file__).resolve().parent.parent
CHAPTER_VARIABLE = "REVIEW_KOANS_CHAPTER"
CHAPTER = re.compile(r"^(\d\d)_")
KOAN_START = re.compile(r'^\s*koan\s+"')
KOAN_HEAD = re.compile(r'^\s*koan\s+"(?P<meditation>(?:[^"\\]|\\.)*)"\s+do\s*$')
RENDERED_VERDICT = re.compile(
    r'verdict\("(?P<file>[^"\n]+)", (?P<answer>[^,\n]+), "(?P<digests>[^"\n]*)", "(?P<source>[^"\n]*)"\)'
)


@dataclass(frozen=True)
class VerdictCall:
    test_path: str
    line: int
    file: str
    answer: int | Literal["fine"]


@dataclass(frozen=True)
class RenderedVerdict:
    line: int
    file: str
    answer: str
    digests: str
    source_digest: str


def chapter_filter() -> str | None:
    value = os.environ.get(CHAPTER_VARIABLE, "").strip()
    if not value:
        return None
    if not re.fullmatch(r"\d\d", value):
        raise ValueError(f"{CHAPTER_VARIABLE} takes two digits, such as 03, not {value!r}")
    return value


def chapter_of(name: str) -> str | None:
    match = CHAPTER.match(name)
    return match.group(1) if match else None


def in_scope(name: str) -> bool:
    chapter = chapter_filter()
    return chapter is None or chapter_of(name) == chapter


def case_id(name: str, *parts: str) -> str:
    return "-".join([f"ch{chapter_of(name)}", Path(name).stem, *parts])


def track_dir(track: str) -> Path:
    return ROOT / track


def tree_test_files(track: str, tree: str) -> list[Path]:
    """Every test file of a tree, sorted by name; `chapter_filter` narrows it to one chapter."""
    dialect = dialect_for(track)
    return [path for path in sorted((track_dir(track) / tree).glob(dialect.test_glob)) if in_scope(path.name)]


def review_renders(track: str) -> dict[str, generate.Review]:
    dialect = dialect_for(track)
    source = track_dir(track) / "source"
    return {
        path.name: generate.render_review(
            path.relative_to(ROOT).as_posix(), path.read_text(encoding="utf-8"), dialect
        )
        for path in sorted(source.glob(dialect.review_glob))
    }


def has_fix(review: generate.Review) -> bool:
    return any(block.kind == "fix" for block in review.blocks)


def rendered_verdicts(text: str) -> list[RenderedVerdict]:
    """The verdict calls of a generated test file, with their answer, digests and source digest."""
    return [
        RenderedVerdict(
            text.count("\n", 0, match.start()) + 1,
            match["file"],
            match["answer"].strip(),
            match["digests"],
            match["source"],
        )
        for match in RENDERED_VERDICT.finditer(text)
    ]


def _answer(text: str, fine: str) -> int | Literal["fine"]:
    if text == fine:
        return "fine"
    if re.fullmatch(r"[1-9][0-9]*", text):
        return int(text)
    raise ValueError(f"verdict answer {text!r} is neither {fine} nor a line number")


def verdict_calls(track: str) -> list[VerdictCall]:
    """Each verdict at its line in the koans tree, with the answer its solutions twin holds."""
    dialect = dialect_for(track)
    calls = []
    for koans_path in tree_test_files(track, "koans"):
        solutions_path = track_dir(track) / "solutions" / koans_path.name
        asked = rendered_verdicts(koans_path.read_text(encoding="utf-8"))
        answered = rendered_verdicts(solutions_path.read_text(encoding="utf-8"))
        if [v.file for v in asked] != [v.file for v in answered]:
            raise ValueError(f"{koans_path.name}: the koans and solutions verdicts name different reviews")
        test_path = koans_path.relative_to(track_dir(track)).as_posix()
        calls.extend(
            VerdictCall(test_path, blank.line, blank.file, _answer(answer.answer, dialect.fine))
            for blank, answer in zip(asked, answered)
        )
    return calls


def koan_lines(text: str) -> list[int]:
    return [number for number, line in enumerate(text.splitlines(), 1) if KOAN_START.match(line)]


def fix_koan_line(test_text: str, verdict_line: int) -> int:
    later = [line for line in koan_lines(test_text) if line > verdict_line]
    if not later:
        raise ValueError(f"no koan follows the verdict on line {verdict_line}")
    return later[0]


def enclosing_koan(test_text: str, line: int) -> int:
    earlier = [start for start in koan_lines(test_text) if start <= line]
    if not earlier:
        raise ValueError(f"line {line} is above every koan")
    return earlier[-1]


def koan_body(test_text: str, koan_line: int) -> str:
    """The text from a koan's head up to the next koan's head, or the end of the file."""
    lines = test_text.splitlines()
    later = [line for line in koan_lines(test_text) if line > koan_line]
    end = later[0] - 1 if later else len(lines)
    return "\n".join(lines[koan_line - 1 : end])


def meditation(test_text: str, koan_line: int) -> str | None:
    match = KOAN_HEAD.match(test_text.splitlines()[koan_line - 1])
    return match["meditation"] if match else None


def _allowlist(allowlist: Path | None) -> set[tuple[str, str]]:
    allowed = set()
    if allowlist is None:
        return allowed
    for number, raw in enumerate(allowlist.read_text(encoding="utf-8").splitlines(), 1):
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        path, _, rest = raw.partition(" | ")
        text, _, reason = rest.rpartition(" | ")
        if not (path.strip() and text.strip() and reason.strip()):
            raise ValueError(f"{allowlist.name}:{number}: write path | line text | reason, with a reason")
        allowed.add((path.strip(), text.strip()))
    return allowed


def static_hits(paths: Iterable[Path], pattern: re.Pattern[str], allowlist: Path | None = None) -> list[str]:
    allowed = _allowlist(allowlist)
    hits = []
    for path in paths:
        shown = path.relative_to(ROOT).as_posix()
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if pattern.search(line) and (shown, line.strip()) not in allowed:
                hits.append(f"{shown}:{number}: {line.strip()}")
    return hits


def files_under(base: Path, folders: Iterable[str], suffixes: tuple[str, ...]) -> list[Path]:
    return [
        path
        for folder in folders
        if (base / folder).is_dir()
        for path in sorted((base / folder).rglob("*"))
        if path.is_file() and path.suffix in suffixes
    ]


def tracked_files() -> list[Path]:
    listed = subprocess.run(
        ["git", "ls-files", "-z"], cwd=ROOT, capture_output=True, text=True, check=True
    ).stdout
    return [ROOT / name for name in listed.split("\0") if name and (ROOT / name).is_file()]
