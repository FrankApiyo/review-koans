"""A koan file whose import fails."""

import review_koans_missing_module


def test_never_runs():
    """This koan never runs."""
    assert review_koans_missing_module
