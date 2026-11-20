from review_koans import __, verdict


def test_cart_verdict():
    """Read verify/fixtures/verdicts/review/cart.py. Write FINE, or the line number of the bug."""
    verdict("cart.py", 4, "94e05d2245,aa563bbdad", "a92ca84232")


def test_fine_verdict():
    """Read verify/fixtures/verdicts/review/fine.py. Write FINE, or the line number of the bug."""
    verdict("fine.py", 2, "6b8a3b3a77", "6fbb391ea2")


def test_value_blank():
    """What is one plus one?"""
    total = 1 + 1
    assert total == __


def test_blank_verdict():
    """Read verify/fixtures/verdicts/review/cart.py. Write FINE, or the line number of the bug."""
    verdict("cart.py", __, "94e05d2245,aa563bbdad", "a92ca84232")
