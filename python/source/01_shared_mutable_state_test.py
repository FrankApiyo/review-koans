"""
Look for: a mutable default argument (`=[]`, `={}`, `=set()`); a lambda or nested `def` in a
loop that reads the loop variable; `[[...]] * n`; `dict(...)`, `copy.copy` or `{**...}` on
nested data that is then written to; a mutable class attribute used as per-instance state.

Why it bites: the language evaluates a default once, when `def` runs, and a class body once,
when `class` runs; every call or instance after that shares the one object. A closure looks
its variables up when it runs, not when it is made. So one request's errors, or one user's
token, shows up in the next request, and nothing fails until two calls happen in one process.

Review habit: Ask what happens with two at once. Call the function twice, or make two
objects, and follow every mutable value back to where it was created. If it was created once,
at definition time or at module level, each write lands where the next caller will read it.

A common mistake: patching the symptom. `errors = errors or []` drops the caller's empty list;
copying an argument the caller shares on purpose breaks callers that rely on it; a shallow
copy of nested data still shares the inner dict. `self.items = self.items + [sku]` happens to
work but leaves the shared list in place for the next method that appends; give each instance
its own list in `__init__`. A traceback can miss the cause: in the `01_note` trace, the field
at fault is on line 7, which no frame prints. Read the error, then find the field it names.

Read more: https://docs.python.org/3.13/faq/programming.html,
https://docs.python.org/3.13/library/copy.html,
https://docs.python.org/3.13/library/dataclasses.html
"""

from review_koans import FINE, __, run_checks, trace, verdict


def test_collect_errors_verdict():
    """Read koans/review/01_collect_errors.py. Write FINE, or the line number of the bug."""
    verdict("01_collect_errors.py", _a(8))


def test_fix_collect_errors():
    """Fix the bug in koans/review/01_collect_errors.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "01_collect_errors")


def test_lambdas_built_in_a_loop():
    """Three lambdas, built in one comprehension. What does each one return?"""
    callbacks = [lambda: i for i in range(3)]
    assert [callback() for callback in callbacks] == _a([2, 2, 2])


def test_handlers_verdict():
    """Read koans/review/01_handlers.py. Write FINE, or the line number of the bug."""
    verdict("01_handlers.py", _a(9))


def test_fix_handlers():
    """Fix the bug in koans/review/01_handlers.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "01_handlers")


def test_a_grid_made_with_star():
    """One cell of a grid is set. What does the grid hold?"""
    grid = [[0] * 3] * 3
    grid[0][0] = 1
    assert grid == _a([[1, 0, 0], [1, 0, 0], [1, 0, 0]])


def test_note_trace():
    """Read traces/01_note.py.trace. Name the exception, then the file and line it came from."""
    assert trace.exception("01_note") == _a("ValueError")
    assert trace.crash_frame("01_note") == _a(("traces/01_note.py", 4))


def test_unique_verdict_and_checks():
    """Read koans/review/01_unique.py. Write FINE, or the line number of the bug."""
    verdict("01_unique.py", _a(FINE))
    run_checks(__file__, "01_unique")


def test_make_config_verdict():
    """Read koans/review/01_make_config.py. Write FINE, or the line number of the bug."""
    verdict("01_make_config.py", _a(7))


def test_fix_make_config():
    """Fix the bug in koans/review/01_make_config.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "01_make_config")


def test_adding_to_a_list_inside_a_tuple():
    """A list inside a tuple is extended with +=. What is raised, and what does the tuple hold?"""
    pair = ([], "label")
    raised = None
    try:
        pair[0] += ["x"]
    except Exception as error:
        raised = type(error).__name__
    assert raised == _a("TypeError")
    assert pair == _a((["x"], "label"))


def test_cart_verdict():
    """Read koans/review/01_cart.py. Write FINE, or the line number of the bug."""
    verdict("01_cart.py", _a(5))


def test_fix_cart():
    """Fix the bug in koans/review/01_cart.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "01_cart")
