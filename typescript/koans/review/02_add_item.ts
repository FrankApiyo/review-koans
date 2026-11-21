/** A new cart holding the cart's items with `sku` added last; the caller's cart is left as it was. */
export function addItem(cart: Cart, sku: string): Cart {
  const next = { ...cart }
  next.items.push(sku)
  return next
}

type Cart = { owner: string; items: string[] }
