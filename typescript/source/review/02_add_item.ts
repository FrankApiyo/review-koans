/** A new cart holding the cart's items with `sku` added last; the caller's cart is left as it was. */
export function addItem(cart: Cart, sku: string): Cart {
  // >>> fix
  const next = { ...cart }
  next.items.push(sku)
  // === fixed
  const next = { ...cart, items: [...cart.items, sku] }
  // === alt: copies the items with concat
  const next = { ...cart, items: cart.items.concat(sku) }
  // === alt: copies the whole cart deeply, then pushes onto the copy
  const next = structuredClone(cart)
  next.items.push(sku)
  // === wrong: refuses — returns a copy that still holds only the old items
  const next = { ...cart, items: [...cart.items] }
  // === wrong: partial — Object.assign is the same shallow copy, so the push still lands on the caller's items
  const next = Object.assign({}, cart)
  next.items.push(sku)
  // === wrong: partial — pushes onto a throwaway copy, so the returned cart never gets the item
  const next = { ...cart }
  ;[...next.items].push(sku)
  // === wrong: partial — names the items in the spread but keeps the caller's list, so the push still lands on it
  const next = { ...cart, items: cart.items }
  next.items.push(sku)
  // <<<
  return next
}

type Cart = { owner: string; items: string[] }
