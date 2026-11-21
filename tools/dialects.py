"""Per-language syntax the generator needs: blanks, scanners, lesson extraction."""

import re
import textwrap
from collections.abc import Callable
from dataclasses import dataclass


@dataclass(frozen=True)
class Dialect:
    name: str
    comment: str
    test_glob: str
    review_glob: str
    value_blank: str
    fine: str
    code_blank: Callable[[str], str]
    function_head: re.Pattern[str]
    module_head: re.Pattern[str]
    find_value_end: Callable[[str, int], int]
    forbidden_in_value: re.Pattern[str]
    lesson: Callable[[str], str | None]
    koan_head: re.Pattern[str]
    meditation: Callable[[list[str], int], str | None]
    top_level_await: re.Pattern[str] | None = None


_SIGIL = re.compile(r"~[a-zA-Z]")
_CHAR_PREFIX = re.compile(r"[A-Za-z0-9_?!]")
_MODULEDOC = re.compile(r'@moduledoc ~S"""\n(.*?)\n[ \t]*"""', re.DOTALL)


def _skip_quoted(text: str, i: int, terminator: str) -> int:
    while i < len(text):
        if text[i] == "\\":
            i += 2
        elif text.startswith(terminator, i):
            return i + len(terminator)
        elif text.startswith("#{", i):
            i = _skip_interpolation(text, i + 2)
        else:
            i += 1
    raise ValueError("unclosed")


def _skip_interpolation(text: str, i: int) -> int:
    depth = 1
    while i < len(text):
        ch = text[i]
        if ch == "}":
            depth -= 1
            i += 1
            if depth == 0:
                return i
        elif ch == "{":
            depth += 1
            i += 1
        elif text.startswith(('"""', "'''"), i):
            i = _skip_quoted(text, i + 3, text[i : i + 3])
        elif ch in "\"'":
            i = _skip_quoted(text, i + 1, ch)
        else:
            i += 1
    raise ValueError("unclosed")


def _elixir_value_end(text: str, start: int) -> int:
    depth = 1
    i = start
    while i < len(text):
        ch = text[i]
        if text.startswith(('"""', "'''"), i):
            i = _skip_quoted(text, i + 3, text[i : i + 3])
        elif ch in "\"'":
            i = _skip_quoted(text, i + 1, ch)
        elif ELIXIR_FORBIDDEN.match(text, i):
            raise ValueError("sigil inside _a(")
        elif ch == "?" and (i == start or not _CHAR_PREFIX.match(text[i - 1])):
            i += 3 if text.startswith("?\\", i) else 2
        elif ch == "#":
            newline = text.find("\n", i)
            if newline == -1:
                break
            i = newline
        elif ch == "(":
            depth += 1
            i += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return i
            i += 1
        else:
            i += 1
    raise ValueError("unclosed _a(")


def _elixir_lesson(text: str) -> str | None:
    match = _MODULEDOC.search(text)
    return textwrap.dedent(match.group(1)).strip("\n") if match else None


ELIXIR_KOAN_HEAD = re.compile(r'^\s*koan\s+"')
_ELIXIR_MEDITATION = re.compile(r'^\s*koan\s+"(?P<meditation>(?:[^"\\]|\\.)*)"\s+do\s*$')


def _elixir_meditation(lines: list[str], koan_line: int) -> str | None:
    match = _ELIXIR_MEDITATION.match(lines[koan_line - 1])
    return match["meditation"] if match else None


ELIXIR_FORBIDDEN = _SIGIL

ELIXIR = Dialect(
    name="elixir",
    comment="#",
    test_glob="*_test.exs",
    review_glob="review/*.ex",
    value_blank="__",
    fine=":fine",
    code_blank=lambda _tag: "__()",
    function_head=re.compile(r"^\s*(def|defp|defmacro|defmacrop)\b"),
    module_head=re.compile(r"^\s*defmodule\b"),
    find_value_end=_elixir_value_end,
    forbidden_in_value=ELIXIR_FORBIDDEN,
    lesson=_elixir_lesson,
    koan_head=ELIXIR_KOAN_HEAD,
    meditation=_elixir_meditation,
)

PYTHON_FORBIDDEN = re.compile(r"(?<![\w])[fF][rR]?['\"]|(?<![\w])[rR][fF]['\"]")
_PYTHON_DOCSTRING = re.compile(r'\A"""\n?(.*?)\n?"""', re.DOTALL)
_PYTHON_MEDITATION = re.compile(r'^\s+"""(.*)"""\s*$')


def _skip_python_string(text: str, i: int) -> int:
    quote = text[i : i + 3] if text.startswith(('"""', "'''"), i) else text[i]
    i += len(quote)
    while i < len(text):
        if text[i] == "\\":
            i += 2
        elif text.startswith(quote, i):
            return i + len(quote)
        else:
            i += 1
    raise ValueError("unclosed _a(")


def _python_value_end(text: str, start: int) -> int:
    depth = 1
    i = start
    while i < len(text):
        ch = text[i]
        if PYTHON_FORBIDDEN.match(text, i):
            raise ValueError("f-string inside _a(")
        if ch in "\"'":
            i = _skip_python_string(text, i)
        elif ch == "#":
            newline = text.find("\n", i)
            if newline == -1:
                break
            i = newline
        elif ch == "(":
            depth += 1
            i += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return i
            i += 1
        else:
            i += 1
    raise ValueError("unclosed _a(")


def _python_lesson(text: str) -> str | None:
    match = _PYTHON_DOCSTRING.search(text)
    return textwrap.dedent(match.group(1)).strip() if match else None


def _python_meditation(lines: list[str], koan_line: int) -> str | None:
    if koan_line >= len(lines):
        return None
    match = _PYTHON_MEDITATION.match(lines[koan_line])
    return match.group(1) if match else None


PYTHON = Dialect(
    name="python",
    comment="#",
    test_glob="*_test.py",
    review_glob="review/*.py",
    value_blank="__",
    fine="FINE",
    code_blank=lambda _tag: "__()",
    function_head=re.compile(r"^\s*(async\s+)?def\b"),
    module_head=re.compile(r"^\s*class\b"),
    find_value_end=_python_value_end,
    forbidden_in_value=PYTHON_FORBIDDEN,
    lesson=_python_lesson,
    koan_head=re.compile(r"^def test_\w+\("),
    meditation=_python_meditation,
)

TYPESCRIPT_FORBIDDEN = re.compile(r"[`/]")
_NOT_A_HEAD = r"(?!(?:if|for|while|switch|catch|return)\b)"
_MODIFIERS = r"(?:(?:static|public|private|protected|override|readonly)\s+)*"
_MEMBER_NAME = r"(#?\w+|\[[^\]]+\])"
_ARROW_START = r"=\s*(async\s*)?(<.*?>\s*)?(\(|\w+\s*=>)"
TS_FUNCTION_HEAD = re.compile(
    r"^\s*(export\s+)?(default\s+)?(async\s+)?function\b"
    rf"|^\s*(export\s+)?(const|let)\s+\w+\s*(:[^=]*)?{_ARROW_START}"
    rf"|^\s+{_NOT_A_HEAD}{_MODIFIERS}(async\s+)?(get\s+|set\s+)?(\*\s*)?{_MEMBER_NAME}\s*"
    rf"((<.*>)?\s*\(|\??\s*(:[^=]*)?{_ARROW_START}).*(\{{|=>)\s*$"
)
_TYPESCRIPT_LESSON = re.compile(r"\A/\*\n(.*?)\n\*/", re.DOTALL)
_TYPESCRIPT_MEDITATION = re.compile(r'^test\("((?:[^"\\]|\\.)*)",')
_TYPESCRIPT_ESCAPE = re.compile(r"\\(.)")


def _skip_typescript_string(text: str, i: int) -> int:
    quote = text[i]
    i += 1
    while i < len(text):
        if text[i] == "\\":
            i += 2
        elif text[i] == quote:
            return i + 1
        else:
            i += 1
    raise ValueError("unclosed _a(")


def _typescript_value_end(text: str, start: int) -> int:
    depth = 1
    i = start
    while i < len(text):
        ch = text[i]
        if ch == "`":
            raise ValueError("template literal inside _a(")
        if ch == "/":
            raise ValueError("slash inside _a(: write the value, not a regex, division or comment")
        if ch in "\"'":
            i = _skip_typescript_string(text, i)
        elif ch == "(":
            depth += 1
            i += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return i
            i += 1
        else:
            i += 1
    raise ValueError("unclosed _a(")


def _typescript_lesson(text: str) -> str | None:
    match = _TYPESCRIPT_LESSON.search(text)
    return textwrap.dedent(match.group(1)).strip() if match else None


def _typescript_meditation(lines: list[str], koan_line: int) -> str | None:
    match = _TYPESCRIPT_MEDITATION.match(lines[koan_line - 1])
    return _TYPESCRIPT_ESCAPE.sub(r"\1", match.group(1)) if match else None


TYPESCRIPT = Dialect(
    name="typescript",
    comment="//",
    test_glob="*_test.ts",
    review_glob="review/*.ts",
    value_blank="__",
    fine='"fine"',
    code_blank=lambda _tag: "__blank()",
    function_head=TS_FUNCTION_HEAD,
    module_head=re.compile(r"^\s*(export\s+)?(default\s+)?(abstract\s+)?class\b"),
    find_value_end=_typescript_value_end,
    forbidden_in_value=TYPESCRIPT_FORBIDDEN,
    lesson=_typescript_lesson,
    koan_head=re.compile(r'^test\("'),
    meditation=_typescript_meditation,
    top_level_await=re.compile(r"^(?:await\b|for\s+await\b|(?:export\s+)?(?:const|let|var)\s[^=]*=\s*await\b)"),
)

DIALECTS: dict[str, Dialect] = {ELIXIR.name: ELIXIR, PYTHON.name: PYTHON, TYPESCRIPT.name: TYPESCRIPT}


def dialect_for(track: str) -> Dialect:
    try:
        return DIALECTS[track]
    except KeyError:
        raise KeyError(f"unknown track {track!r}; known tracks: {', '.join(DIALECTS)}") from None
