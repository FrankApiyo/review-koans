"""
Look for: `is` between values; a one-item tuple written without its comma; a dataclass with
`eq=False`, or a hash over fields that can still change; a generator or iterator read twice; a
dict or list changed inside a loop over it; `zip` over inputs that may differ in length.

Why it bites: none of these raise. `("active")` is a string, so `in` matches any part of it. A
generator is empty after one full pass, so a second `sum` over it is 0. `zip` stops at the
shorter input. With `eq=False`, equal records compare and hash by identity, so a set keeps both.
The answer is just smaller: a row, a duplicate or a refusal goes missing.

Review habit: Ask who supplied the value. `is` compares identity, which is the language's rule;
whether a string parsed from JSON is the same object as the literal in your source is CPython's
behaviour, and here it is not. A parameter typed `Iterable` may be a reader that runs once. A
header row and a data row come from different places and can disagree in length.

A common mistake: fixing what the eye lands on. `rows = list(rows)` copies the input but still
reads one generator twice, and `filter(...)` is one pass too. `unsafe_hash=True` dedupes equal
SKUs but loses one edited after it went into a set; `frozen=True` refuses the edit. A length
check in one direction catches half the bad rows. A traceback can name the wrong line: the
`02_drop_expired` trace points at the `for` on line 2, but the `del` on line 4 changed the dict.

Read more: https://docs.python.org/3.13/reference/expressions.html,
https://docs.python.org/3.13/library/dataclasses.html,
https://docs.python.org/3.13/library/itertools.html
"""

from review_koans import FINE, __, run_checks, trace, verdict


def test_can_login_verdict():
    """Read koans/review/02_can_login.py. Write FINE, or the line number of the bug."""
    verdict("02_can_login.py", __, "8a977fd595,de1890aa24", "1d1241e99e")


def test_fix_can_login():
    """Fix the bug in koans/review/02_can_login.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "02_can_login")


def test_nan_in_a_list():
    """NaN is compared with itself, then looked for in two lists. What are the three results?"""
    nan = float("nan")
    assert [nan == nan, nan in [nan], nan in [float("nan")]] == __


def test_skus_verdict():
    """Read koans/review/02_skus.py. Write FINE, or the line number of the bug."""
    verdict("02_skus.py", __, "6d8ada79cf", "a1bd331e50")


def test_fix_skus():
    """Fix the bug in koans/review/02_skus.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "02_skus")


def test_drop_expired_trace():
    """Read traces/02_drop_expired.py.trace. Name the exception, then the file and line it came from."""
    assert trace.exception("02_drop_expired") == __
    assert trace.crash_frame("02_drop_expired") == __


def test_removing_from_a_list_in_a_loop_over_it():
    """Each 2 is removed while a loop walks the list. What is left?"""
    nums = [1, 2, 2, 3]
    for n in nums:
        if n == 2:
            nums.remove(n)
    assert nums == __


def test_summarize_verdict():
    """Read koans/review/02_summarize.py. Write FINE, or the line number of the bug."""
    verdict("02_summarize.py", __, "dfffcab1b9,ee98017176,f7d9f2fcbb", "5886a0f089")


def test_fix_summarize():
    """Fix the bug in koans/review/02_summarize.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "02_summarize")


def test_prune_verdict_and_checks():
    """Read koans/review/02_prune.py. Write FINE, or the line number of the bug."""
    verdict("02_prune.py", __, "30e594669e", "2ac4133d87")
    run_checks(__file__, "02_prune")


def test_pair_row_verdict():
    """Read koans/review/02_pair_row.py. Write FINE, or the line number of the bug."""
    verdict("02_pair_row.py", __, "3eb50f39f3", "c46edcaf75")


def test_fix_pair_row():
    """Fix the bug in koans/review/02_pair_row.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "02_pair_row")
