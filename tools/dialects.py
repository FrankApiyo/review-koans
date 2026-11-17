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
)

DIALECTS: dict[str, Dialect] = {ELIXIR.name: ELIXIR}


def dialect_for(track: str) -> Dialect:
    try:
        return DIALECTS[track]
    except KeyError:
        raise KeyError(f"unknown track {track!r}; known tracks: {', '.join(DIALECTS)}") from None
