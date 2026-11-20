"""Prices are in whole, non-negative cents, and a discount is a whole percent from 0 to 100.

The discount is rounded down to whole cents.
"""


def discounted(price_cents: int, percent: int) -> int:
    # >>> fix
    return price_cents - price_cents * percent // 10
    # === fixed
    return price_cents - price_cents * percent // 100
    # === wrong: refuses — returns 0 for every price
    return 0
    # === wrong: partial — rounds the price down, so 10 % off an odd price is a cent short
    return price_cents * (100 - percent) // 100
    # <<<
