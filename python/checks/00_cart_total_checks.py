from review_koans.checks import exploit, twin


def empty_cart(review):
    assert review.total([]) == 0


def single_units(review):
    assert review.total([{"qty": 1, "unit_cents": 250}, {"qty": 1, "unit_cents": 200}]) == 450


def several_units(review):
    assert review.total([{"qty": 3, "unit_cents": 250}, {"qty": 1, "unit_cents": 200}]) == 950


CASES = [
    twin("an empty cart", empty_cart),
    twin("single units", single_units),
    exploit("a line with several units", several_units),
]
