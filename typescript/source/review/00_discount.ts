/** The price after a percent discount, in whole cents; the discount is rounded down. */
export function discounted(priceCents: number, percent: number): number {
  // >>> fix
  return priceCents - Math.floor((priceCents * percent) / 10)
  // === fixed
  return priceCents - Math.floor((priceCents * percent) / 100)
  // === alt: rounds the discounted price up, which leaves the discount rounded down
  return Math.ceil((priceCents * (100 - percent)) / 100)
  // === alt: names the discount before taking it off
  const discount = Math.floor((priceCents * percent) / 100)
  return priceCents - discount
  // === wrong: refuses — returns 0 for every price
  return 0
  // === wrong: partial — rounds the price down, so 10 % off an odd price is a cent short
  return Math.floor((priceCents * (100 - percent)) / 100)
  // === wrong: partial — scales by a fractional percent, so some whole-cent discounts come out a cent short
  return priceCents - Math.floor(priceCents * (percent / 100))
  // <<<
}
