from review_koans.checks import exploit, raises, twin


def matching(review):
    assert review.pair_row(["id", "email"], ["7", "ada@example.com"]) == {"id": "7", "email": "ada@example.com"}


def empty(review):
    assert review.pair_row([], []) == {}


def missing_value(review):
    with raises(ValueError):
        review.pair_row(["id", "email"], ["7"])


def extra_value(review):
    with raises(ValueError):
        review.pair_row(["id"], ["7", "x"])


CASES = [
    twin("a row that matches its headers", matching),
    twin("an empty row under no headers", empty),
    exploit("a row with a value missing", missing_value),
    exploit("a row with an extra value", extra_value),
]
