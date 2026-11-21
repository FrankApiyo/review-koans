/** Returns the price of `sku`, or `undefined` when it has none. */
export function price(prices: Record<string, number>, sku: string): number | undefined {
  if (!(sku in prices)) throw new RangeError(`no price for ${sku}`)
  return prices[sku]
}
