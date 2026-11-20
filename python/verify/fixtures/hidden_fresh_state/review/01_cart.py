_added = []


def add(sku):
    """Records sku and returns every sku recorded so far."""
    _added.append(sku)
    return list(_added)
