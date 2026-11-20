from review_koans import __


def _doubled(n):
    return n * 2 == __


def test_helper():
    """What is two doubled?"""
    assert _doubled(2)
