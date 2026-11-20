"""Lesson format: five parts, 30 lines at most, and Read more links from tools/links.txt."""

import re
from dataclasses import dataclass
from pathlib import Path

import pytest

from dialects import DIALECTS
from harness import ROOT, case_id, chapter_filter, in_scope

LINKS = ROOT / "tools" / "links.txt"
PARTS = ("Look for:", "Why it bites:", "Review habit:", "A common mistake:", "Read more:")
HABITS = (
    "Name the other process",
    "Ask what happens on crash",
    "Ask what happens with two at once",
    "Ask who supplied the value",
    "Read for what is missing",
)
# Chapter 00 teaches how the koans work, not a review topic, so it has no five-part lesson.
FIVE_PART_EXEMPT = {"00"}
MAX_LINES = 30
URL = re.compile(r"https?://[^\s)>\]]+")


@dataclass(frozen=True)
class Lesson:
    id: str
    chapter: str
    path: Path
    text: str | None


def lessons() -> list[Lesson]:
    found = []
    for track, dialect in DIALECTS.items():
        for path in sorted((ROOT / track / "source").glob(dialect.test_glob)):
            if in_scope(path.name):
                chapter = path.name[:2]
                text = dialect.lesson(path.read_text(encoding="utf-8"))
                found.append(Lesson(case_id(path.name, track), chapter, path, text))
    return found


LESSONS = lessons()


def paragraphs(text: str) -> list[str]:
    return [part.strip() for part in re.split(r"\n\s*\n", text) if part.strip()]


def paragraph(text: str, start: str) -> str | None:
    return next((p for p in paragraphs(text) if p.startswith(start)), None)


def five_part(lesson: Lesson) -> Lesson:
    if lesson.chapter in FIVE_PART_EXEMPT:
        pytest.skip(f"chapter {lesson.chapter} is exempt from the five-part rule")
    assert lesson.text is not None, f"{lesson.path.name} has no lesson"
    return lesson


@pytest.mark.parametrize("lesson", LESSONS, ids=lambda lesson: lesson.id)
def test_lessons_have_five_parts(lesson):
    text = five_part(lesson).text
    assert [part for part in PARTS if paragraph(text, part) is None] == []
    habit = paragraph(text, "Review habit:")
    assert [name for name in HABITS if name in habit], f"the habit names none of {HABITS}"


@pytest.mark.parametrize("lesson", LESSONS, ids=lambda lesson: lesson.id)
def test_lessons_fit_in_30_lines(lesson):
    assert lesson.text is not None, f"{lesson.path.name} has no lesson"
    assert len(lesson.text.splitlines()) <= MAX_LINES


def allowlisted_links() -> set[str]:
    return set(LINKS.read_text(encoding="utf-8").splitlines())


@pytest.mark.parametrize("lesson", LESSONS, ids=lambda lesson: lesson.id)
def test_read_more_has_2_to_4_allowlisted_links(lesson):
    read_more = paragraph(five_part(lesson).text, "Read more:") or ""
    links = [url.rstrip(".,;") for url in URL.findall(read_more)]
    assert 2 <= len(links) <= 4, links
    assert [url for url in links if url not in allowlisted_links()] == []


def test_links_file_is_sorted_and_unique():
    lines = LINKS.read_text(encoding="utf-8").splitlines()
    assert lines == sorted(set(lines))
    assert [line for line in lines if not line.startswith("https://")] == []


PAGE = ROOT / "lessons" / "index.html"


def test_lessons_page_is_current():
    import lessons

    assert PAGE.read_text(encoding="utf-8") == lessons.build(), "run: python tools/lessons.py"


def test_page_has_no_pictures_or_scripts():
    page = PAGE.read_text(encoding="utf-8").lower()
    assert [tag for tag in ("<img", "<svg", "<script", "<link", "@import") if tag in page] == []


def test_every_read_more_link_is_an_anchor():
    page = PAGE.read_text(encoding="utf-8")
    anchors = set(re.findall(r'<a href="([^"]+)">', page))
    linked = {
        url.rstrip(".,;")
        for lesson in LESSONS
        if lesson.text and (more := paragraph(lesson.text, "Read more:"))
        for url in URL.findall(more)
    }
    if not linked and chapter_filter():
        pytest.skip("no lesson in this chapter has Read more links")
    assert linked and linked <= anchors


def tokens_missing_from_dark(page: str) -> list[str]:
    light = re.search(r":root \{(.*?)\}", page, re.DOTALL).group(1)
    dark = re.search(r"prefers-color-scheme: dark\) \{\s*:root \{(.*?)\}", page, re.DOTALL)
    defined = set(re.findall(r"(--[\w-]+):", dark.group(1) if dark else ""))
    return [token for token in re.findall(r"(--[\w-]+):", light) if token not in defined]


def test_page_has_light_and_dark_colours():
    page = PAGE.read_text(encoding="utf-8")
    assert "color-scheme: light dark" in page
    assert "--bg:" in page
    assert tokens_missing_from_dark(page) == []


def test_dark_check_catches_a_missing_dark_token():
    page = PAGE.read_text(encoding="utf-8")
    assert tokens_missing_from_dark(page.replace("    --bg: #15171b;\n", "")) == ["--bg"]


def test_page_declares_language_title_and_viewport():
    page = PAGE.read_text(encoding="utf-8")
    assert '<html lang="en">' in page
    assert re.search(r"<title>[^<]+</title>", page)
    assert '<meta name="viewport" content="width=device-width, initial-scale=1">' in page


def test_inline_escapes_html_and_sets_code():
    import lessons

    assert lessons.inline("a<b & c>d") == "a&lt;b &amp; c&gt;d"
    assert lessons.inline("set x=1 now") == "set <code>x=1</code> now"
    assert (
        lessons.inline('see `%{"id" => "2"}` here')
        == 'see <code>%{"id" =&gt; "2"}</code> here'
    )


TRACKS_WITH_SOURCES = [track for track in DIALECTS if (ROOT / track / "source").is_dir()]


@pytest.mark.parametrize("track", TRACKS_WITH_SOURCES)
def test_articles_follow_chapter_order_with_readable_titles(track):
    import lessons

    page = PAGE.read_text(encoding="utf-8")
    section = re.search(rf'<section id="{track}">\n(.*?)</section>', page, re.DOTALL)
    assert section, f"the page has no {track} section"
    sources = sorted((ROOT / track / "source").glob(DIALECTS[track].test_glob))
    assert re.findall(rf'<article id="{track}-(\d\d)">', section[1]) == [path.name[:2] for path in sources]
    titles = re.findall(r"<h3><small>\d\d</small>([^<]+)</h3>", section[1])
    assert titles[0] == "How review koans work"
    assert titles == [lessons.TITLES[name] for _, name, _ in lessons.chapters(ROOT, track)]


def test_chapter_without_lesson_is_an_error(tmp_path):
    import lessons

    source = tmp_path / "elixir" / "source"
    source.mkdir(parents=True)
    (source / "01_processes_and_mailboxes_test.exs").write_text("defmodule X do\nend\n")
    with pytest.raises(ValueError, match="no lesson"):
        lessons.chapters(tmp_path, "elixir")


def test_chapter_without_display_title_is_an_error():
    import lessons

    with pytest.raises(KeyError):
        lessons.title_for("unmapped chapter")


def test_read_more_inside_prose_does_not_split_the_lesson():
    import lessons

    html = lessons.section_html("elixir", "01", "ets", "Intro says Read more: later.\n\nRead more: https://a.example/x")
    assert "Intro says Read more: later." in html
    assert '<a href="https://a.example/x">' in html
