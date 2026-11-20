"""Chapter 00's lesson quotes real footers; these tests keep its locations true to the koans tree."""

import re

from dialects import ELIXIR
from harness import ROOT, enclosing_koan, koan_lines, meditation

KOANS = ROOT / "elixir" / "koans"
TEST_FILE = "00_how_review_koans_work_test.exs"
TEXT = (KOANS / TEST_FILE).read_text(encoding="utf-8")
LESSON = ELIXIR.lesson(TEXT) or ""
MEDITATE = re.compile(r"^\s*Meditate on koans/(?P<file>\S+):(?P<line>\d+)$", re.M)
HIDDEN = re.compile(
    r"^\s*A hidden case still fails: (?P<label>.+)\n"
    r"\s*-+ The master says -+\n"
    r"\s*Write: +koans/review/(?P<review>\S+)\n"
    r"\s*Exercised by: koans/(?P<file>\S+):(?P<line>\d+)\n"
    r"\s*(?P<meditation>.+)\n"
    r"\s*(?P<passed>\d+) of (?P<total>\d+) koans answered\.$",
    re.M,
)
BLANK = re.compile(r"(?<!\w)__(?!\w)")
DEFMODULE = re.compile(r"^defmodule (?P<name>[\w.]+) do$", re.M)
LABELS = re.compile(r'\{:(?P<kind>exploit|twin), "(?P<label>[^"]+)"')


def whole_track_koans() -> int:
    return sum(
        len(re.findall(r'^  koan "', f.read_text(encoding="utf-8"), re.M))
        for f in KOANS.glob("[0-9][0-9]_*_test.exs")
    )


def line_of(number: int) -> str:
    return TEXT.splitlines()[number - 1]


def test_the_lesson_quotes_both_footers():
    assert len(MEDITATE.findall(LESSON)) == 1
    assert len(HIDDEN.findall(LESSON)) == 1


def test_the_blank_footer_names_the_first_blank():
    quoted = MEDITATE.search(LESSON)
    first_koan = koan_lines(TEXT)[0]
    first_blank = next(n for n, text in enumerate(TEXT.splitlines(), 1) if n > first_koan and BLANK.search(text))
    assert quoted["file"] == TEST_FILE
    assert int(quoted["line"]) == first_blank


def test_the_hidden_case_footer_names_the_fix_koan_and_its_review():
    quoted = HIDDEN.search(LESSON)
    line = int(quoted["line"])
    review = (KOANS / "review" / quoted["review"]).read_text(encoding="utf-8")
    module = DEFMODULE.search(review)["name"]
    koan = enclosing_koan(TEXT, line)
    assert quoted["file"] == TEST_FILE
    assert re.fullmatch(rf"\s*run_checks\([\w.]+, {re.escape(module)}\)", line_of(line))
    assert meditation(TEXT, koan) == quoted["meditation"].strip()
    assert int(quoted["passed"]) == koan_lines(TEXT).index(koan)
    assert int(quoted["total"]) == whole_track_koans()


def test_the_quoted_label_is_the_first_exploit_of_its_checks():
    # The buggy module passes every twin, so the first exploit is the label it shows.
    quoted = HIDDEN.search(LESSON)
    checks = (ROOT / "elixir" / "checks" / quoted["review"].replace(".ex", "_checks.ex")).read_text(encoding="utf-8")
    exploits = [m["label"] for m in LABELS.finditer(checks) if m["kind"] == "exploit"]
    assert exploits
    assert quoted["label"] == exploits[0]
