import warehouse_client


def add(cart, sku, quantity):
    """Returns a new cart holding quantity more of sku."""
    return {**cart, sku: cart.get(sku, 0) + quantity}
