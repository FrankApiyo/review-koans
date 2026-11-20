from review_koans.checks import exploit


def unknown_item(review):
    assert review.price({}, "GHOST-1") is None


CASES = [exploit("an unknown item", unknown_item)]
