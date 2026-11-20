"""Prices are in whole, non-negative cents, and a discount is a whole percent from 0 to 100.

The discount is rounded down to whole cents.
"""


def discounted(price_cents: int, percent: int) -> int:
    return price_cents - price_cents * percent // 100
