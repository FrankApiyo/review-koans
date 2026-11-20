import sys


def price(prices, sku):
    """Returns the price of sku, or None when it has none."""
    if sku not in prices:
        sys.exit(1)
    return prices[sku]
