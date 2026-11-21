"""Build lessons/index.html from the lesson that opens each chapter's source file.

Run from the repo root:

    python tools/lessons.py
"""

import re
from html import escape
from pathlib import Path

from dialects import DIALECTS

ROOT = Path(__file__).resolve().parent.parent
PAGE = ROOT / "lessons" / "index.html"
READ_MORE = "Read more:"
MISTAKE = "A common mistake:"
TRAILING = ".,;:!?"
URL = re.compile(r"https?://[^\s)>\]]+")
BACKTICKED = re.compile(r"(`[^`]+`)")

TITLES = {
    "how review koans work": "How review koans work",
    "processes and mailboxes": "Processes and mailboxes",
    "links monitors and exits": "Links, monitors and exits",
    "genserver calls and timeouts": "GenServer calls and timeouts",
    "supervision and restarts": "Supervision and restarts",
    "ets": "ETS",
    "ecto queries and transactions": "Ecto queries and transactions",
    "liveview": "LiveView",
    "quire": "Quire",
    "shared mutable state": "Shared mutable state",
    "equality hashing and iteration": "Equality, hashing and iteration",
    "exceptions": "Exceptions",
    "asyncio": "asyncio",
    "money time files and injection": "Money, time, files and injection",
    "equality numbers and sorting": "Equality, numbers and sorting",
    "references and copies": "References and copies",
    "this and closures": "this and closures",
    "async ordering": "Async ordering",
    "untrusted data and dates": "Untrusted data and dates",
}

STYLE = """\
:root {
  color-scheme: light dark;
  --bg: #fdfdfb;
  --fg: #1d2127;
  --muted: #5b6470;
  --accent: #5b3a9e;
  --code-bg: #eeeaf5;
  --rule: #d9d6e0;
  --mistake: #fbeee9;
}
@media (prefers-color-scheme: dark) {
  :root {
    --bg: #15171b;
    --fg: #e4e6ea;
    --muted: #9aa3ae;
    --accent: #b79cf0;
    --code-bg: #262a33;
    --rule: #333844;
    --mistake: #2b2321;
  }
}
body { background: var(--bg); color: var(--fg); font: 17px/1.55 system-ui, sans-serif; margin: 0; }
main { max-width: 46rem; margin: 0 auto; padding: 1.5rem 16px 4rem; }
h1 { font-size: 1.8rem; }
h2 { font-size: 1.3rem; margin-top: 2.5rem; border-bottom: 1px solid var(--rule); }
h3 small { color: var(--muted); margin-right: 0.6rem; font-weight: 400; }
a { color: var(--accent); overflow-wrap: anywhere; }
code, pre { background: var(--code-bg); border-radius: 4px; font-size: 0.9em; }
code { padding: 0.05em 0.3em; overflow-wrap: anywhere; }
pre { padding: 0.7rem 1rem; overflow-x: auto; }
pre code { padding: 0; }
.mistake { background: var(--mistake); padding: 0.5rem 0.8rem; border-radius: 4px; }
.more { color: var(--muted); margin-bottom: 0.2rem; }
.links { margin-top: 0; }
nav { display: flex; flex-wrap: wrap; gap: 0.3rem 1rem; }
footer { color: var(--muted); margin-top: 3rem; font-size: 0.9rem; }
"""


def _is_code(core: str) -> bool:
    has_letter = any(c.isalpha() for c in core)
    return "_" in core or "://" in core or ("=" in core and has_letter)


def _trim(token: str) -> tuple[str, str, str]:
    """(lead, core, tail): the punctuation of the sentence around a token, and the token."""
    start, end = 0, len(token)
    while start < end:
        core = token[start:end]
        if core[-1] in TRAILING:
            end -= 1
        elif core[-1] in ')"' and _unbalanced(core, core[-1]):
            end -= 1
        elif core[0] in '("' and _unbalanced(core, core[0]):
            start += 1
        elif core[0] == "(" and core[-1] == ")" and core.count("(") == 1:
            start, end = start + 1, end - 1
        else:
            break
    return token[:start], token[start:end], token[end:]


def _unbalanced(core: str, mark: str) -> bool:
    if mark == '"':
        return core.count('"') % 2 == 1
    return core.count("(") != core.count(")")


def _inline_token(token: str) -> str:
    lead, core, tail = _trim(token)
    if not (core and _is_code(core)):
        return escape(token, quote=False)
    lead, core, tail = (escape(part, quote=False) for part in (lead, core, tail))
    return f"{lead}<code>{core}</code>{tail}"


def inline(text: str) -> str:
    """Escape text for HTML; backticked spans, identifiers and URLs are set in code."""
    parts = BACKTICKED.split(text)
    return "".join(
        f"<code>{escape(part[1:-1], quote=False)}</code>"
        if index % 2
        else "".join(_inline_token(token) for token in re.split(r"(\s+)", part))
        for index, part in enumerate(parts)
    )


def _blocks(text: str) -> list[list[str]]:
    blocks, current = [], []
    for line in text.splitlines():
        if line.strip():
            current = [*current, line]
        elif current:
            blocks, current = [*blocks, current], []
    return [*blocks, current] if current else blocks


def _list_items(lines: list[str]) -> list[str]:
    items = []
    for line in lines:
        if line.startswith("- "):
            items = [*items, line[2:].strip()]
        else:
            items = [*items[:-1], f"{items[-1]} {line.strip()}"]
    return items


def _block_html(lines: list[str]) -> str:
    if lines[0].startswith("    "):
        code = escape("\n".join(line[4:] for line in lines), quote=False)
        return f"<pre><code>{code}</code></pre>"
    if lines[0].startswith("- "):
        items = "".join(f"<li>{inline(item)}</li>" for item in _list_items(lines))
        return f"<ul>{items}</ul>"
    text = " ".join(line.strip() for line in lines)
    if text.startswith(MISTAKE):
        rest = text.removeprefix(MISTAKE).strip()
        return f'<p class="mistake"><strong>{escape(MISTAKE)}</strong> {inline(rest)}</p>'
    return f"<p>{inline(text)}</p>"


def _links_html(urls: list[str]) -> str:
    if not urls:
        return ""
    items = "".join(f'<li><a href="{escape(url)}">{escape(url, quote=False)}</a></li>' for url in urls)
    return f'<p class="more">Read more</p>\n<ul class="links">{items}</ul>\n'


def title_for(name: str) -> str:
    return TITLES[name]


def chapters(root: Path, track: str) -> list[tuple[str, str, str]]:
    """(number, short name, lesson) for every chapter of a track, in file order."""
    dialect = DIALECTS[track]
    found = []
    for path in sorted((root / track / "source").glob(dialect.test_glob)):
        number, _, rest = path.name.split("_test.")[0].partition("_")
        lesson = dialect.lesson(path.read_text(encoding="utf-8"))
        if not lesson:
            raise ValueError(f"{path.name} has no lesson")
        found = [*found, (number, rest.replace("_", " "), lesson)]
    return found


def _split_read_more(lesson: str) -> tuple[str, str]:
    parts = re.split(rf"(?m)^{re.escape(READ_MORE)}", lesson, maxsplit=1)
    return (parts[0], parts[1]) if len(parts) == 2 else (lesson, "")


def section_html(track: str, number: str, name: str, lesson: str) -> str:
    body, more = _split_read_more(lesson)
    paragraphs = "\n".join(_block_html(block) for block in _blocks(body))
    urls = [url.rstrip(".,;") for url in URL.findall(more)]
    return (
        f'<article id="{track}-{number}">\n'
        f"<h3><small>{number}</small>{escape(title_for(name), quote=False)}</h3>\n"
        f"{paragraphs}\n{_links_html(urls)}</article>\n"
    )


def track_html(root: Path, track: str) -> str:
    articles = "\n".join(
        section_html(track, number, name, lesson) for number, name, lesson in chapters(root, track)
    )
    return f'<section id="{track}">\n<h2>{escape(track.capitalize())}</h2>\n{articles}</section>\n'


def build(root: Path = ROOT) -> str:
    """The whole page, the same text on every run."""
    tracks = [track for track in DIALECTS if (root / track / "source").is_dir()]
    nav = "".join(f'<a href="#{track}">{escape(track.capitalize())}</a>' for track in tracks)
    sections = "\n".join(track_html(root, track) for track in tracks)
    return (
        "<!doctype html>\n"
        '<html lang="en">\n<head>\n<meta charset="utf-8">\n'
        '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
        "<title>Review koans lessons</title>\n"
        f"<style>\n{STYLE}</style>\n</head>\n<body>\n<main>\n"
        "<h1>Review koans lessons</h1>\n"
        '<p class="lead">The lesson from the top of each chapter. Everything here works '
        "offline; only the Read more links leave the page.</p>\n"
        f"<nav>{nav}</nav>\n\n{sections}"
        "<footer>Built by <code>tools/lessons.py</code> from the lessons in each track's "
        "<code>source/</code> folder. Lessons are under CC BY 4.0; see "
        "<code>LICENSE-lessons</code>.</footer>\n"
        "</main>\n</body>\n</html>\n"
    )


def main() -> int:
    PAGE.parent.mkdir(parents=True, exist_ok=True)
    PAGE.write_text(build(), encoding="utf-8")
    print("lessons/index.html")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
