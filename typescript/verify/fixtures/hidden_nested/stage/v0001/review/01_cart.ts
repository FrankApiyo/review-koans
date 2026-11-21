/** Returns a new cart holding `quantity` more of `sku`. */
export function add(cart: Record<string, number>, sku: string, quantity: number): Record<string, number> {
  return { ...cart, [sku]: (cart[sku] ?? 0) + quantity }
}
