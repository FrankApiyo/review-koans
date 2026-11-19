"""Generate <track>/koans and <track>/solutions from <track>/source.

Usage: python tools/generate.py [--check] [track ...]
"""

import argparse
import hashlib
import re
import sys
from collections.abc import Callable, Mapping
from dataclasses import dataclass, replace
from pathlib import Path
from typing import Literal

from dialects import DIALECTS, Dialect, dialect_for

ROOT = Path(__file__).resolve().parent.parent
VALUE_MARKER = re.compile(r"(?<![A-Za-z0-9_?!@.])_a\(")
VERDICT_CALL = re.compile(r"\bverdict\(")
VERDICT = re.compile(r'verdict\("(?P<file>[^"\n]+)", _a\((?P<answer>[^()\n]*)\)\)')
LINE_NUMBER = re.compile(r"[1-9][0-9]*")
SEPARATOR = " — "
ANSWER_TAG = "answer"
REVIEW_TAGS = ("fix", "guard")
WRONG_TAGS = ("refuses", "partial")
TREES = ("koans", "solutions")
SENTINEL = "\x00blank\x00"


class GenerationError(Exception):
    pass


@dataclass(frozen=True)
class Half:
    kind: Literal["wrong", "alt"]
    tag: Literal["refuses", "partial"] | None
    description: str
    lines: tuple[str, ...]


@dataclass(frozen=True)
class Also:
    fragment: str
    reason: str
    line: int


@dataclass(frozen=True)
class Block:
    kind: Literal["fix", "guard"]
    source_line: int
    koans_start: int
    buggy: tuple[str, ...]
    fixed: tuple[str, ...]
    halves: tuple[Half, ...]
    also: tuple[Also, ...]


@dataclass(frozen=True)
class Review:
    path: str
    koans: str
    solutions: str
    blocks: tuple[Block, ...]
    accepted: frozenset[int]
    source_digest: str


@dataclass(frozen=True)
class Blank:
    kind: Literal["value", "code", "verdict"]
    index: int
    source_line: int


@dataclass(frozen=True)
class _Raw:
    tag: str
    line: int
    indent: str
    body: tuple[tuple[int, str], ...]
    start: int
    end: int


@dataclass(frozen=True)
class _AlsoMarker:
    fragment: str
    reason: str
    line: int


@dataclass(frozen=True)
class _Verdict:
    file: str
    answer: int | Literal["fine"]
    answer_text: str
    line: int
    start: int
    end: int


@dataclass(frozen=True)
class _BlankSpan:
    blank: Blank
    start: int
    end: int
    indent: str
    verdict: int


def digest(file: str, answer: int | Literal["fine"]) -> str:
    return hashlib.sha256(f"{file}:{answer}".encode("utf-8")).hexdigest()[:10]


def _sha(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:10]


def _line_of(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def _split_lines(text: str) -> list[str]:
    parts = text.split("\n")
    return [part + "\n" for part in parts[:-1]] + ([parts[-1]] if parts[-1] else [])


def _indent(line: str) -> int:
    return len(line) - len(line.lstrip())


def _open(dialect: Dialect) -> str:
    return f"{dialect.comment} >>> "


def render_values(path: str, text: str, dialect: Dialect, *, solved: bool) -> str:
    out = []
    pos = 0
    while match := VALUE_MARKER.search(text, pos):
        end = _value_end(path, text, match, dialect)
        inner = text[match.end() : end]
        if VALUE_MARKER.search(inner):
            raise GenerationError(f"{path}:{_line_of(text, match.start())}: nested _a(")
        out.append(text[pos : match.start()])
        out.append(inner if solved else dialect.value_blank)
        pos = end + 1
    out.append(text[pos:])
    return "".join(out)


def _value_end(path: str, text: str, match: re.Match[str], dialect: Dialect) -> int:
    try:
        return dialect.find_value_end(text, match.end())
    except ValueError as error:
        raise GenerationError(f"{path}:{_line_of(text, match.start())}: {error}") from None


def _segments(path: str, text: str, dialect: Dialect) -> list[str | _Raw]:
    opener, closer = _open(dialect), f"{dialect.comment} <<<"
    out: list[str | _Raw] = []
    raw = None
    offset = 0
    for number, line in enumerate(_split_lines(text), 1):
        stripped = line.strip()
        if stripped.startswith(opener) and raw is None:
            tag = stripped[len(opener) :].strip()
            raw = _Raw(tag, number, line[: _indent(line)], (), offset, offset)
        elif stripped.startswith(opener):
            raise GenerationError(f"{path}:{number}: nested {opener.strip()} inside line {raw.line}")
        elif stripped == closer:
            if raw is None:
                raise GenerationError(f"{path}:{number}: {closer} without {opener.strip()}")
            out.append(replace(raw, end=offset + len(line)))
            raw = None
        elif raw is not None:
            raw = replace(raw, body=(*raw.body, (number, line)))
        else:
            out.append(line)
        offset += len(line)
    if raw is not None:
        raise GenerationError(f"{path}:{raw.line}: unclosed {opener}{raw.tag}")
    return out


def render_code_blocks(path: str, text: str, dialect: Dialect, *, solved: bool) -> str:
    out = []
    for segment in _segments(path, text, dialect):
        if isinstance(segment, str):
            out.append(segment)
        elif segment.tag in REVIEW_TAGS:
            raise GenerationError(f"{path}:{segment.line}: {_open(dialect)}{segment.tag} outside a review file")
        elif segment.tag != ANSWER_TAG:
            raise GenerationError(f"{path}:{segment.line}: unknown block {_open(dialect)}{segment.tag}")
        elif solved:
            out.extend(line for _, line in segment.body)
        else:
            out.append(f"{segment.indent}{dialect.code_blank('')}\n")
    return "".join(out)


def _render(path: str, text: str, dialect: Dialect, *, solved: bool) -> str:
    render_values(path, text, dialect, solved=solved)
    blocks = render_code_blocks(path, text, dialect, solved=solved)
    return render_values(path, blocks, dialect, solved=solved)


# Review files: fix and guard blocks.


def _parse_also(path: str, number: int, content: str) -> _AlsoMarker:
    fragment, _, reason = content.partition(SEPARATOR.rstrip())
    if not reason.strip():
        raise GenerationError(f"{path}:{number}: also: needs a reason after{SEPARATOR}")
    return _AlsoMarker(fragment.strip(), reason.strip(), number)


def _parse_header(path: str, number: int, header: str) -> tuple[str, str | None, str]:
    if header == "fixed":
        return "fixed", None, ""
    kind, colon, rest = header.partition(":")
    tag, description = None, rest.strip()
    if kind == "wrong" and colon:
        tag, _, description = (part.strip() for part in rest.partition(SEPARATOR.strip()))
        if tag not in WRONG_TAGS:
            raise GenerationError(f"{path}:{number}: wrong: tag must be one of {', '.join(WRONG_TAGS)}")
    elif kind != "alt" or not colon:
        raise GenerationError(f"{path}:{number}: unknown separator {header!r}")
    if not description:
        raise GenerationError(f"{path}:{number}: {kind}: needs a description")
    return kind, tag, description


def _sections(path: str, raw: _Raw, dialect: Dialect) -> tuple[list[dict], tuple[_AlsoMarker, ...]]:
    separator, also_prefix = f"{dialect.comment} ===", f"{dialect.comment} also:"
    sections = [{"kind": "shown", "tag": None, "description": "", "line": raw.line, "lines": []}]
    alsos = []
    for number, line in raw.body:
        stripped = line.strip()
        if stripped.startswith(also_prefix):
            if raw.tag != "fix" or len(sections) > 1 or sections[0]["lines"]:
                raise GenerationError(f"{path}:{number}: also: lines come straight after {_open(dialect)}fix")
            alsos.append(_parse_also(path, number, stripped[len(also_prefix) :]))
        elif stripped.startswith(separator):
            kind, tag, description = _parse_header(path, number, stripped[len(separator) :].strip())
            sections.append({"kind": kind, "tag": tag, "description": description, "line": number, "lines": []})
        else:
            sections[-1]["lines"].append(line.removesuffix("\n"))
    return sections, tuple(alsos)


def _halves(sections: list[dict]) -> tuple[Half, ...]:
    return tuple(Half(s["kind"], s["tag"], s["description"], tuple(s["lines"])) for s in sections)


def _fix_block(path: str, raw: _Raw, sections: list[dict]) -> Block:
    fixed = [s for s in sections if s["kind"] == "fixed"]
    if len(sections) < 2 or sections[1]["kind"] != "fixed" or len(fixed) > 1:
        raise GenerationError(f"{path}:{raw.line}: fix block needs one === fixed half, straight after the buggy half")
    halves = _halves(sections[2:])
    for tag in WRONG_TAGS:
        if not any(half.tag == tag for half in halves):
            raise GenerationError(f"{path}:{raw.line}: fix block needs a wrong: {tag} half")
    buggy, fixed_lines = tuple(sections[0]["lines"]), tuple(sections[1]["lines"])
    if not any(line.strip() for line in buggy + fixed_lines):
        raise GenerationError(f"{path}:{raw.line}: fix block has an empty buggy half and an empty fixed half")
    return Block("fix", raw.line, 0, buggy, fixed_lines, halves, ())


def _guard_block(path: str, raw: _Raw, sections: list[dict]) -> Block:
    if any(s["kind"] == "fixed" for s in sections):
        raise GenerationError(f"{path}:{raw.line}: guard block has no fixed half")
    if not any(s["kind"] == "wrong" for s in sections):
        raise GenerationError(f"{path}:{raw.line}: guard block needs a wrong: half")
    for section in sections:
        if section["tag"] == "refuses":
            raise GenerationError(f"{path}:{section['line']}: guard wrong: halves are tagged partial")
    shown = tuple(sections[0]["lines"])
    return Block("guard", raw.line, 0, shown, shown, _halves(sections[1:]), ())


def _parse_review(
    path: str, text: str, dialect: Dialect
) -> tuple[list[str | int], tuple[Block, ...], tuple[tuple[_AlsoMarker, ...], ...]]:
    segments: list[str | int] = []
    blocks, alsos = [], []
    for segment in _segments(path, text, dialect):
        if isinstance(segment, str):
            segments.append(segment)
            continue
        if segment.tag not in REVIEW_TAGS:
            raise GenerationError(f"{path}:{segment.line}: {_open(dialect)}{segment.tag} in a review file")
        sections, markers = _sections(path, segment, dialect)
        build = _fix_block if segment.tag == "fix" else _guard_block
        segments.append(len(blocks))
        blocks.append(build(path, segment, sections))
        alsos.append(markers)
    return segments, tuple(blocks), tuple(alsos)


def _assemble(
    segments: list[str | int], blocks: tuple[Block, ...], choose: Callable[[int, Block], tuple[str, ...]]
) -> tuple[str, list[int]]:
    out, starts = [], []
    line = 1
    for segment in segments:
        if isinstance(segment, str):
            out.append(segment)
            line += 1
        else:
            lines = choose(segment, blocks[segment])
            starts.append(line)
            out.extend(f"{text}\n" for text in lines)
            line += len(lines)
    return "".join(out), starts


def _walk_up(lines: list[str], index: int, threshold: int, is_head: Callable[[str], bool]) -> int | None:
    for i in range(index - 1, -1, -1):
        line = lines[i]
        if line.strip() and _indent(line) < threshold:
            if is_head(line):
                return i + 1
            threshold = _indent(line)
    return None


def _nearest_text(lines: list[str], indices: range) -> int | None:
    return next((i + 1 for i in indices if lines[i].strip()), None)


def _block_indent(block: Block) -> int:
    first = next(line for line in block.buggy + block.fixed if line.strip())
    return _indent(first)


def _span_lines(path: str, lines: list[str], block: Block, dialect: Dialect) -> set[int]:
    start = block.koans_start
    if any(line.strip() for line in block.buggy):
        return {start + k for k, line in enumerate(block.buggy) if line.strip()}
    head = _walk_up(
        lines,
        start - 1,
        _block_indent(block),
        lambda line: bool(dialect.function_head.match(line) or dialect.module_head.match(line)),
    )
    if head is None:
        raise GenerationError(f"{path}:{block.source_line}: omission with no enclosing function or module head")
    before = _nearest_text(lines, range(start - 2, -1, -1))
    after = _nearest_text(lines, range(start - 1 + len(block.buggy), len(lines)))
    return {line for line in (before, after, head) if line}


def _module_of(lines: list[str], index: int, threshold: int, dialect: Dialect) -> int | None:
    return _walk_up(lines, index, threshold, lambda line: bool(dialect.module_head.match(line)))


def _also_lines(path: str, lines: list[str], block: Block, markers, dialect: Dialect) -> tuple[Also, ...]:
    if not markers:
        return ()
    module =_module_of(lines, block.koans_start - 1, _block_indent(block), dialect)
    found = []
    for marker in markers:
        matches = [n for n, line in enumerate(lines, 1) if marker.fragment in line]
        if len(matches) != 1:
            raise GenerationError(
                f"{path}:{marker.line}: also: {marker.fragment!r} must match exactly one line"
                f" of the koans render, not {len(matches)}"
            )
        [line] = matches
        if _module_of(lines, line - 1, _indent(lines[line - 1]), dialect) != module:
            raise GenerationError(f"{path}:{marker.line}: also: {marker.fragment!r} is not in the block's module")
        found.append(Also(marker.fragment, marker.reason, line))
    return tuple(found)


def _review_parts(path: str, text: str, dialect: Dialect) -> tuple[list[str | int], tuple[Block, ...], str]:
    segments, blocks, alsos = _parse_review(path, text, dialect)
    koans, starts = _assemble(segments, blocks, lambda _i, block: block.buggy)
    lines = koans.split("\n")
    placed = []
    for block, start, markers in zip(blocks, starts, alsos):
        block = replace(block, koans_start=start)
        placed.append(replace(block, also=_also_lines(path, lines, block, markers, dialect)))
    return segments, tuple(placed), koans


def render_review(path: str, text: str, dialect: Dialect) -> Review:
    segments, blocks, koans = _review_parts(path, text, dialect)
    lines = koans.split("\n")
    accepted = {
        line
        for block in blocks
        if block.kind == "fix"
        for line in _span_lines(path, lines, block, dialect) | {also.line for also in block.also}
    }
    solutions, _ = _assemble(segments, blocks, lambda _i, block: block.fixed)
    return Review(path, koans, solutions, blocks, frozenset(accepted), _sha(koans))


def render_review_with(path: str, text: str, dialect: Dialect, block: int, half: int | None) -> str:
    segments, blocks, _ = _review_parts(path, text, dialect)
    if not 0 <= block < len(blocks):
        raise GenerationError(f"{path}: no block {block}; it has {len(blocks)}")
    chosen = blocks[block]
    if half is None and chosen.kind == "guard":
        raise GenerationError(f"{path}:{chosen.source_line}: a guard block only takes a half")
    if half is not None and not 0 <= half < len(chosen.halves):
        raise GenerationError(f"{path}:{chosen.source_line}: no half {half}; it has {len(chosen.halves)}")
    variant = chosen.buggy if half is None else chosen.halves[half].lines
    rendered, _ = _assemble(segments, blocks, lambda i, b: variant if i == block else b.fixed)
    return rendered


# Test files: verdicts and blanks.


def _verdicts(path: str, text: str, dialect: Dialect) -> list[_Verdict]:
    found = []
    for call in VERDICT_CALL.finditer(text):
        line = _line_of(text, call.start())
        match = VERDICT.match(text, call.start())
        if match is None:
            raise GenerationError(f'{path}:{line}: verdict must be one line: verdict("<file>", _a(<answer>))')
        answer_text = match["answer"].strip()
        if answer_text == dialect.fine:
            answer = "fine"
        elif LINE_NUMBER.fullmatch(answer_text):
            answer = int(answer_text)
        else:
            raise GenerationError(f"{path}:{line}: verdict answer must be {dialect.fine} or a line number")
        found.append(_Verdict(match["file"], answer, answer_text, line, match.start(), match.end()))
    return found


def _has_fix(review: Review) -> bool:
    return any(block.kind == "fix" for block in review.blocks)


def _checked_review(path: str, verdict: _Verdict, reviews: Mapping[str, Review], dialect: Dialect) -> Review:
    where, name = f"{path}:{verdict.line}", verdict.file
    review = reviews.get(name)
    if review is None:
        raise GenerationError(f"{where}: verdict names review/{name}, which does not exist")
    if not _has_fix(review) and verdict.answer != "fine":
        raise GenerationError(f"{where}: {name} has no fix block, so its verdict answer must be {dialect.fine}")
    if _has_fix(review) and verdict.answer == "fine":
        raise GenerationError(f"{where}: {name} has a fix block, so its verdict answer is a line of it")
    if _has_fix(review) and verdict.answer not in review.accepted:
        raise GenerationError(
            f"{where}: verdict answer {verdict.answer} is not an accepted line of {name}: {sorted(review.accepted)}"
        )
    return review


def _digests(file: str, review: Review) -> str:
    if not review.accepted:
        return digest(file, "fine")
    return ",".join(sorted(digest(file, line) for line in review.accepted))


def _substitute_verdicts(
    path: str, text: str, dialect: Dialect, reviews: Mapping[str, Review], slot: Callable[[int, str], str]
) -> str:
    out, pos = [], 0
    for index, verdict in enumerate(_verdicts(path, text, dialect)):
        review = _checked_review(path, verdict, reviews, dialect)
        answer = slot(index, verdict.answer_text)
        out.append(text[pos : verdict.start])
        out.append(f'verdict("{verdict.file}", {answer}, "{_digests(verdict.file, review)}", "{review.source_digest}")')
        pos = verdict.end
    out.append(text[pos:])
    return "".join(out)


def render_test(path: str, text: str, dialect: Dialect, reviews: Mapping[str, Review]) -> tuple[str, str]:
    hidden = _substitute_verdicts(path, text, dialect, reviews, lambda _i, _a: dialect.value_blank)
    shown = _substitute_verdicts(path, text, dialect, reviews, lambda _i, answer: answer)
    return _render(path, hidden, dialect, solved=False), _render(path, shown, dialect, solved=True)


def _blank_spans(path: str, text: str, dialect: Dialect) -> list[_BlankSpan]:
    verdicts = _verdicts(path, text, dialect)
    found = [(v.start, "verdict", v.end, "", n) for n, v in enumerate(verdicts)]
    for match in VALUE_MARKER.finditer(text):
        if not any(v.start <= match.start() < v.end for v in verdicts):
            found.append((match.start(), "value", _value_end(path, text, match, dialect) + 1, "", -1))
    for segment in _segments(path, text, dialect):
        if isinstance(segment, _Raw) and segment.tag == ANSWER_TAG:
            found.append((segment.start, "code", segment.end, segment.indent, -1))
    return [
        _BlankSpan(Blank(kind, index, _line_of(text, start)), start, end, indent, verdict)
        for index, (start, kind, end, indent, verdict) in enumerate(sorted(found))
    ]


def blanks(path: str, text: str, dialect: Dialect) -> list[Blank]:
    return [span.blank for span in _blank_spans(path, text, dialect)]


def render_test_variant(
    path: str, text: str, dialect: Dialect, reviews: Mapping[str, Review], blank: int
) -> tuple[str, int]:
    spans = _blank_spans(path, text, dialect)
    if not 0 <= blank < len(spans):
        raise GenerationError(f"{path}: no blank {blank}; it has {len(spans)}")
    span = spans[blank]
    source = text
    if span.blank.kind == "value":
        source = text[: span.start] + SENTINEL + text[span.end :]
    elif span.blank.kind == "code":
        source = f"{text[: span.start]}{span.indent}{SENTINEL}\n{text[span.end :]}"
    def slot(index: int, answer: str) -> str:
        return SENTINEL if index == span.verdict else answer

    rendered = _render(path, _substitute_verdicts(path, source, dialect, reviews, slot), dialect, solved=True)
    line = _line_of(rendered, rendered.index(SENTINEL))
    blank_text = dialect.code_blank("") if span.blank.kind == "code" else dialect.value_blank
    return rendered.replace(SENTINEL, blank_text), line


# Tracks.


def _relative(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def _visible_files(folder: Path) -> list[Path]:
    return [
        path
        for path in sorted(folder.rglob("*"))
        if path.is_file() and not any(part.startswith(".") for part in path.relative_to(folder).parts)
    ]


def _check_one_verdict_each(reviews: Mapping[str, Review], verdicts: list[tuple[str, _Verdict]]) -> None:
    named = set()
    for path, verdict in verdicts:
        review = reviews[verdict.file]
        if _has_fix(review) and verdict.file in named:
            raise GenerationError(f"{path}:{verdict.line}: {verdict.file} already has a verdict")
        named.add(verdict.file)
    for name, review in reviews.items():
        if _has_fix(review) and name not in named:
            first = next(block for block in review.blocks if block.kind == "fix")
            raise GenerationError(f"{review.path}:{first.source_line}: no verdict names {name}")


def render_track(track: str, root: Path = ROOT) -> dict[Path, str]:
    dialect = dialect_for(track)
    base = root / track
    source_dir = base / "source"
    if not source_dir.is_dir():
        raise GenerationError(f"{_relative(source_dir, root)} is not a directory")
    texts = {path.relative_to(source_dir): path.read_text(encoding="utf-8") for path in _visible_files(source_dir)}
    shown = {relative: _relative(source_dir / relative, root) for relative in texts}
    outputs: dict[Path, tuple[str, str]] = {}
    reviews: dict[str, Review] = {}
    for relative, text in texts.items():
        if relative.full_match(dialect.review_glob):
            review = render_review(shown[relative], text, dialect)
            reviews[relative.name] = review
            outputs[relative] = (review.koans, review.solutions)
    verdicts = []
    for relative, text in texts.items():
        if relative.full_match(dialect.test_glob):
            outputs[relative] = render_test(shown[relative], text, dialect, reviews)
            verdicts.extend((shown[relative], v) for v in _verdicts(shown[relative], text, dialect))
        elif relative not in outputs:
            outputs[relative] = tuple(_render(shown[relative], text, dialect, solved=s) for s in (False, True))
    _check_one_verdict_each(reviews, verdicts)
    return {base / tree / relative: pair[i] for relative, pair in outputs.items() for i, tree in enumerate(TREES)}


def _existing(track: str, root: Path) -> set[Path]:
    return {path for tree in TREES for path in _visible_files(root / track / tree)}


def _problems(track: str, root: Path, outputs: dict[Path, str]) -> list[str]:
    problems = []
    for path, content in outputs.items():
        if not path.exists():
            problems.append(f"missing: {_relative(path, root)}")
        elif path.read_text(encoding="utf-8") != content:
            problems.append(f"stale: {_relative(path, root)}")
    problems.extend(f"orphan: {_relative(p, root)}" for p in sorted(_existing(track, root) - outputs.keys()))
    return problems


def _write(track: str, root: Path, outputs: dict[Path, str]) -> None:
    for path, content in outputs.items():
        if not path.exists() or path.read_text(encoding="utf-8") != content:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")
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
