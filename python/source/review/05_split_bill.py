"""Group payments. split_bill divides a bill into one share per person."""

from decimal import Decimal


def split_bill(total: Decimal, people: int) -> list[Decimal]:
    """Returns one share per person, in whole cents; the shares add up to total and differ by at most a cent."""
    # >>> fix
    share = round(total / people, 2)
    return [share] * people
    # === fixed
    from decimal import ROUND_DOWN

    cent = Decimal("0.01")
    share = (total / people).quantize(cent, rounding=ROUND_DOWN)
    leftover = int((total - share * people) / cent)
    return [share + cent if person < leftover else share for person in range(people)]
    # === alt: divmod on whole cents
    base, leftover = divmod(int(total * 100), people)
    return [Decimal(base + 1 if person < leftover else base) / 100 for person in range(people)]
    # === wrong: refuses — splits nothing
    return []
    # === wrong: partial — float shares, the last takes the rest
    share = round(float(total) / people, 2)
    rest = round(float(total) - share * (people - 1), 2)
    return [Decimal(share)] * (people - 1) + [Decimal(rest)]
    # === wrong: partial — rounded shares, the last takes the rest
    share = round(total / people, 2)
    return [share] * (people - 1) + [total - share * (people - 1)]
    # <<<
