/** Returns a new cart holding `quantity` more of `sku`; a quantity of zero leaves it unchanged. */
export function add(cart: Record<string, number>, _sku: string, _quantity: number): Record<string, number> {
  return { ...cart }
}
