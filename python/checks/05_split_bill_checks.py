from decimal import Decimal

from review_koans.checks import exploit, twin

CENT = Decimal("0.01")


def shares_for(review, total, people):
    shares = review.split_bill(Decimal(total), people)
    assert len(shares) == people
    assert sum(shares) == Decimal(total)
    assert all(share == share.quantize(CENT) for share in shares)
    assert max(shares) - min(shares) <= CENT
    return shares


def even(review):
    assert shares_for(review, "90.00", 3) == [Decimal("30.00")] * 3


def a_cent_over(review):
    shares_for(review, "100.00", 3)


def cents_over(review):
    shares_for(review, "0.05", 3)
    shares_for(review, "1.00", 7)


CASES = [
    twin("a bill that splits evenly", even),
    exploit("a bill that leaves a cent over", a_cent_over),
    exploit("a bill that leaves several cents over", cents_over),
]
