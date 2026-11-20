def add(cart, sku, quantity:
    return {**cart, sku: cart.get(sku, 0) + quantity}
