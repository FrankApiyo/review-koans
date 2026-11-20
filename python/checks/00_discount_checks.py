from review_koans.checks import exploit, twin


def no_discount(review):
    assert review.discounted(1000, 0) == 1000


def ordinary_discount(review):
    assert review.discounted(1000, 10) == 900


def uneven_discount(review):
    assert review.discounted(999, 10) == 900


CASES = [
    twin("a price with no discount", no_discount),
    exploit("an ordinary discount", ordinary_discount),
    exploit("a discount that does not divide evenly", uneven_discount),
]
