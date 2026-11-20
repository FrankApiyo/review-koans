"""
Look for: a `float` anywhere money is parsed, added or split; `Decimal` built from a float; a
rounded share multiplied back up; `replace(tzinfo=...)` on a time that has an offset; a naive
`datetime` beside an aware one, or one from `utcnow` (deprecated since 3.12); a file opened
outside `with`; SQL, a path or a shell command built from a value with an f-string or `+`.

Why it bites: a binary float cannot hold 0.1 exactly, so sums drift, and 2.675 is stored just
below itself. `round` sends an exact half to the even neighbour (the language's rule). A
`Decimal` made from a float keeps the float's error. Rounded shares rarely add back up to the
total. `replace(tzinfo=...)` keeps the wall clock and moves the instant; `astimezone` keeps the
instant, and reads a naive time as the machine's local time. Ordering a naive and an aware time
raises `TypeError`; `==` between them is just `False`. A file whose `close` an exception skips
stays open until the garbage collector reaches it. A quote in a value ends an SQL string
literal. `os.path.join` drops the base when the name is absolute, and `..` climbs out of it.

Review habit: Ask who supplied the value. A name, a path, a body or a time that came with a
request is data until the code proves otherwise. Follow it to the SQL text, the shell string,
the path or the sum, and ask what its worst value does there.

A common mistake: fixing the sample instead of the rule. Escaping quotes by hand still builds
the SQL text from the value; refusing every name that holds `..` refuses honest names and still
lets an absolute path through; comparing the start of two path strings also matches a sibling
folder whose name begins the same way; letting the last share take the rest can leave it more
than a cent from the others; returning `None` on a parse error hides the error and still leaves
the file open. In the `05_is_expired` trace, line 5 only compares; the naive time was made on
line 9.

Read more: https://docs.python.org/3.13/library/decimal.html,
https://docs.python.org/3.13/library/datetime.html,
https://docs.python.org/3.13/library/sqlite3.html,
https://docs.python.org/3.13/library/subprocess.html
"""

from review_koans import FINE, __, run_checks, trace, verdict


def test_floats_and_round():
    """Floats added, compared and rounded. What does each line give?"""
    assert (0.1 + 0.2 == 0.3) == False
    assert 0.1 + 0.2 == 0.30000000000000004
    assert round(2.675, 2) == 2.67
    assert (round(0.5), round(1.5), round(2.5)) == (0, 2, 2)


def test_split_bill_verdict():
    """Read koans/review/05_split_bill.py. Write FINE, or the line number of the bug."""
    verdict("05_split_bill.py", 8, "097ed780ae,8d15045547", "efcce0e8a0")


def test_fix_split_bill():
    """Fix the bug in koans/review/05_split_bill.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "05_split_bill")


def test_payment_total_verdict_and_checks():
    """Read koans/review/05_payment_total.py. Write FINE, or the line number of the bug."""
    verdict("05_payment_total.py", FINE, "71ab6c8670", "ffab80c8f2")
    run_checks(__file__, "05_payment_total")


def test_is_expired_trace():
    """Read traces/05_is_expired.py.trace. Name the exception, then the file and line it came from."""
    assert trace.exception("05_is_expired") == "TypeError"
    assert trace.crash_frame("05_is_expired") == ("traces/05_is_expired.py", 5)


def test_to_utc_verdict():
    """Read koans/review/05_to_utc.py. Write FINE, or the line number of the bug."""
    verdict("05_to_utc.py", 8, "e356695e51", "a3308d09c9")


def test_fix_to_utc():
    """Fix the bug in koans/review/05_to_utc.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "05_to_utc")


def test_load_config_verdict():
    """Read koans/review/05_load_config.py. Write FINE, or the line number of the bug."""
    verdict("05_load_config.py", 9, "3c3cbf6c3e,72037fa244,cdc14a536e", "ca1a63fa43")


def test_fix_load_config():
    """Fix the bug in koans/review/05_load_config.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "05_load_config")


def test_find_email_verdict():
    """Read koans/review/05_find_email.py. Write FINE, or the line number of the bug."""
    verdict("05_find_email.py", 6, "8972c98d78,e607b2ccea", "2f52efbc15")


def test_fix_find_email():
    """Fix the bug in koans/review/05_find_email.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "05_find_email")


def test_read_upload_verdict():
    """Read koans/review/05_read_upload.py. Write FINE, or the line number of the bug."""
    verdict("05_read_upload.py", 8, "3fd571f737", "14878c674c")


def test_fix_read_upload():
    """Fix the bug in koans/review/05_read_upload.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "05_read_upload")


def test_search_verdict_and_checks():
    """Read koans/review/05_search.py. Write FINE, or the line number of the bug."""
    verdict("05_search.py", FINE, "053127c2d4", "d29685c83f")
    run_checks(__file__, "05_search")
