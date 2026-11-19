from harness import CHAPTER_VARIABLE, chapter_filter


def pytest_report_header(config) -> str:
    chapter = chapter_filter()
    if chapter is None:
        return f"{CHAPTER_VARIABLE} unset: whole-track run"
    return f"{CHAPTER_VARIABLE}={chapter}: chapter {chapter} only, not the whole track"


def pytest_terminal_summary(terminalreporter) -> None:
    terminalreporter.write_line(pytest_report_header(terminalreporter.config))
