"""
Look for: `except Exception` around code that can fail for more than one reason; a `from None`
inside a handler; a broad handler above a narrower one; `continue` or `pass` as the whole
handler; a handler that raises again; a name bound by `except ... as` and read after the block.

Why it bites: the program keeps going with the wrong answer. A port of `80a` becomes 8080, and
a failed push drops out of the report. The language tries `except` clauses top to bottom, so
for an Exception subclass a handler below `except Exception` never runs. `from None` hides the
context in the traceback without deleting it, and `__cause__` stays `None`, so a caller that
reads the cause gets nothing. The language also deletes the `as` name when its handler ends,
even a name bound before `try`.

Review habit: Read for what is missing. For each handler, ask which exceptions it catches that
its author did not mean, and what record of the failure is left once it has run: a status, an
entry in a list, a `__cause__`. An empty handler, or a `from None`, is a choice to lose one.
Which `OSError` deleting a directory gives is the platform's: macOS and Linux differ.

A common mistake: narrowing in one place only. `except (KeyError, ValueError)` still turns a
bad port into 8080; moving only `ValueError` up still sends `NotFound` to 500; `append` then
`break` reports the first failure only; dropping `from None` shows the context again, but
`__cause__` is still `None`. Checking that a file exists before unlinking it races: another
process can delete it in between, so the unlink still meets a missing file. A chained
traceback prints two errors. In the `03_parse_order` trace, the first is the request's fault
(a missing value at column 22) and the last is the code's. In the `03_last_error` trace, the
handler on line 6 deleted the name the `return` reads.

Read more: https://docs.python.org/3.13/tutorial/errors.html,
https://docs.python.org/3.13/library/exceptions.html,
https://docs.python.org/3.13/reference/compound_stmts.html
"""

from review_koans import FINE, __, run_checks, trace, verdict


def test_load_port_verdict():
    """Read koans/review/03_load_port.py. Write FINE, or the line number of the bug."""
    verdict("03_load_port.py", __, "3de431f160,57240629dd,996abaa33f,ea24c43f32", "e98fa273ba")


def test_fix_load_port():
    """Fix the bug in koans/review/03_load_port.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "03_load_port")


def test_raise_from_none():
    """A LookupError is raised while a KeyError is handled, once plainly and once from None. What does each keep?"""

    def find(stock, sku, quiet):
        try:
            return stock[sku]
        except KeyError:
            if quiet:
                raise LookupError("no sku") from None
            raise LookupError("no sku")

    def chain(quiet):
        try:
            find({}, "A1", quiet)
        except LookupError as error:
            return [type(error.__context__).__name__, error.__cause__, error.__suppress_context__]

    assert chain(quiet=False) == __
    assert chain(quiet=True) == __


def test_charge_verdict():
    """Read koans/review/03_charge.py. Write FINE, or the line number of the bug."""
    verdict("03_charge.py", __, "06956fb342,db37c2e8e9", "2cfb7db294")


def test_fix_charge():
    """Fix the bug in koans/review/03_charge.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "03_charge")


def test_parse_order_trace():
    """Read traces/03_parse_order.py.trace. Name both exceptions in order, then the file and line of the last."""
    assert trace.exceptions("03_parse_order") == __
    assert trace.crash_frame("03_parse_order") == __


def test_status_for_verdict():
    """Read koans/review/03_status_for.py. Write FINE, or the line number of the bug."""
    verdict("03_status_for.py", __, "605f9298b7,661bf0453c,71c4622ede,8caff1798a,a3decd8a19,fcb81353f8", "7741b983d5")


def test_fix_status_for():
    """Fix the bug in koans/review/03_status_for.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "03_status_for")


def test_discard_verdict_and_checks():
    """Read koans/review/03_discard.py. Write FINE, or the line number of the bug."""
    verdict("03_discard.py", __, "4198363c03", "ccac406bd8")
    run_checks(__file__, "03_discard")


def test_sync_verdict():
    """Read koans/review/03_sync.py. Write FINE, or the line number of the bug."""
    verdict("03_sync.py", __, "1f338a9359,9a9b1cf26b", "d761052fc0")


def test_fix_sync():
    """Fix the bug in koans/review/03_sync.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "03_sync")


def test_last_error_trace():
    """Read traces/03_last_error.py.trace. Name the exception, then the file and line it came from."""
    assert trace.exception("03_last_error") == __
    assert trace.crash_frame("03_last_error") == __
