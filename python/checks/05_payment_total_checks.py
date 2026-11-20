from decimal import Decimal

from review_koans.checks import exploit, twin


def whole_amount(review):
    assert review.payment_total('{"amount": 10, "fee": 0.25}') == Decimal("10.25")


def fractions(review):
    assert review.payment_total('{"amount": 0.1, "fee": 0.2}') == Decimal("0.3")
    assert review.payment_total('{"amount": 19.99, "fee": 0.01}') == Decimal("20.00")


CASES = [
    twin("a whole amount with a fee", whole_amount),
    exploit("an amount and a fee in tenths and hundredths", fractions),
]
