const prices: Record<string, number> = await new Promise(() => {})

/** Returns the price of `sku`. */
export function price(sku: string): number | undefined {
  return prices[sku]
}
