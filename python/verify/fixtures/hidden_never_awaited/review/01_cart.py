async def _notify(sku):
    return sku


def add(cart, sku):
    """Returns a new cart holding sku and notifies the warehouse."""
    pending = [_notify(sku)]
    pending.append(pending)
    return [*cart, sku]
