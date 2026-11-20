from review_koans import FINE, verdict


def test_cart_verdict():
    """Read verify/fixtures/solved/review/cart.py. Write FINE, or the line number of the bug."""
    verdict("cart.py", 4, "94e05d2245,aa563bbdad", "a92ca84232")


def test_fine_verdict():
    """Read verify/fixtures/solved/review/fine.py. Write FINE, or the line number of the bug."""
    verdict("fine.py", FINE, "6b8a3b3a77", "6fbb391ea2")


def test_value():
    """What is one plus one?"""
    assert 1 + 1 == 2
