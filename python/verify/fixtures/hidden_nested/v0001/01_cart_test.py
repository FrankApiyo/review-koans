from review_koans import run_checks


def test_fix_the_cart():
    """Fix the bug in verify/fixtures/hidden_nested/v0001/review/01_cart.py in place. The hidden checks name what still fails."""
    run_checks(__file__, "01_cart")
