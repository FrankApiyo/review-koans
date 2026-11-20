"""
Review koans come in three kinds, and each one fails until you answer it.

- Predict: replace `__` with the value that makes the assertion true.
- Review: read the module in `koans/review/`, then replace the `__` in its verdict with
  `FINE`, or with the number of the line that holds the bug. About one review in five is
  fine. After a bug, the next koan has you fix it in place, and hidden checks run your fix.
- Trace: read a real crash captured in `traces/`, and name its cause and where it came from.

`pytest` stops at the first koan that fails, and its footer says where to work. A blank:

    Meditate on koans/00_how_review_koans_work_test.py:37

A fix names the file to change and the koan that runs its checks. A failing check shows its
label, never a raw value or the fix:

    A hidden case still fails: an ordinary discount
    ------------------------------- The master says --------------------------------
    Write:        koans/review/00_discount.py
    Exercised by: koans/00_how_review_koans_work_test.py:47
        Fix the bug in koans/review/00_discount.py in place. The hidden checks name what still fails.
    2 of 30 koans answered.

The checks are readable in `checks/`, as the answers are in `solutions/`. Read them only after
a real attempt; reading them first defeats the exercise.

An import error in a koan file stops the run before any footer: fix what the traceback names,
then run `pytest` again. A fix that loops forever never returns; press Ctrl-C to stop the run.
To start again, run `git checkout -- koans/`.
"""

from review_koans import FINE, __, run_checks, trace, verdict


def test_a_predict_koan():
    """A predict koan: the blank holds the value that makes the assertion true."""
    assert 40 + 2 == __


def test_discount_verdict():
    """Read koans/review/00_discount.py. Write FINE, or the line number of the bug."""
    verdict("00_discount.py", __, "ff57135599", "9758acd88e")


def test_fix_the_discount():
    """Fix the bug in koans/review/00_discount.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "00_discount")


def test_cart_total_verdict_and_checks():
    """Read koans/review/00_cart_total.py. Write FINE, or the line number of the bug."""
    verdict("00_cart_total.py", __, "d2eb36e3cf", "ef1e6e0e86")
    run_checks(__file__, "00_cart_total")


def test_divide_trace():
    """Read traces/00_divide.py.trace. Name the exception, then the file and line it came from."""
    assert trace.exception("00_divide") == __
    assert trace.crash_frame("00_divide") == __
