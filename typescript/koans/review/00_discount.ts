/** The price after a percent discount, in whole cents; the discount is rounded down. */
export function discounted(priceCents: number, percent: number): number {
  return priceCents - Math.floor((priceCents * percent) / 10)
}
