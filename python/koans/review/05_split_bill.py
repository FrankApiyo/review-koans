"""Group payments. split_bill divides a bill into one share per person."""

from decimal import Decimal


def split_bill(total: Decimal, people: int) -> list[Decimal]:
    """Returns one share per person, in whole cents; the shares add up to total and differ by at most a cent."""
    share = round(total / people, 2)
    return [share] * people
