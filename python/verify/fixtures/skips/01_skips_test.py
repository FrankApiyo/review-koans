import pytest


def test_passes():
    """One is one."""
    assert 1 == 1


def test_skipped():
    """A skipped koan."""
    pytest.skip("not today")


@pytest.mark.xfail(reason="expected")
def test_expected_failure():
    """An expected failure."""
    assert 1 == 2
