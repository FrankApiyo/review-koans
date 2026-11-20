from pathlib import Path

import pytest

from review_koans import trace

FIXTURES = Path(__file__).parent / "fixtures"


@pytest.fixture(autouse=True)
def in_fixtures(monkeypatch):
    monkeypatch.chdir(FIXTURES)


def test_read_returns_the_captured_text():
    assert trace.read("boom").startswith("exit 1\n--- stdout\n--- stderr\nTraceback")


def test_exceptions_lists_every_exception_that_ends_a_traceback():
    assert trace.exceptions("boom") == ["KeyError"]
    assert trace.exceptions("chained") == ["json.decoder.JSONDecodeError", "AttributeError"]
    assert trace.exceptions("group") == ["ExceptionGroup", "ValueError"]


def test_exception_is_the_last_one_and_never_the_message():
    assert trace.exception("chained") == "AttributeError"
    assert trace.exception("group") == "ValueError"
    assert "qty" not in trace.exception("boom")


def test_frames_lists_course_frames_in_printed_order():
    assert trace.frames("boom") == [("traces/boom.py", 5), ("traces/boom.py", 2)]
    assert trace.frames("chained") == [
        ("traces/chained.py", 6),
        ("traces/chained.py", 11),
        ("traces/chained.py", 8),
    ]
    assert trace.frames("group") == [
        ("traces/group.py", 17),
        ("traces/group.py", 12),
        ("traces/group.py", 7),
    ]


def test_crash_frame_is_the_innermost_course_frame_of_the_last_traceback():
    assert trace.crash_frame("boom") == ("traces/boom.py", 2)
    assert trace.crash_frame("chained") == ("traces/chained.py", 8)
    assert trace.crash_frame("group") == ("traces/group.py", 7)


def test_a_trace_without_a_traceback_has_no_exception_or_frame(tmp_path, monkeypatch):
    (tmp_path / "traces").mkdir()
    (tmp_path / "traces" / "quiet.py.trace").write_text("exit 0\n--- stdout\nok\n--- stderr\n")
    monkeypatch.chdir(tmp_path)

    assert trace.exceptions("quiet") == []
    assert trace.exception("quiet") is None
    assert trace.crash_frame("quiet") is None
