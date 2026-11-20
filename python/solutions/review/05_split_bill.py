"""Group payments. split_bill divides a bill into one share per person."""

from decimal import Decimal


def split_bill(total: Decimal, people: int) -> list[Decimal]:
    """Returns one share per person, in whole cents; the shares add up to total and differ by at most a cent."""
    from decimal import ROUND_DOWN

    cent = Decimal("0.01")
    share = (total / people).quantize(cent, rounding=ROUND_DOWN)
    leftover = int((total - share * people) / cent)
    return [share + cent if person < leftover else share for person in range(people)]
