/** A price in dollars, given to at most two decimal places, as a whole number of cents. */
// >>> fix
export const toCents = (price: number): number => Math.floor(price * 100)
// === fixed
export const toCents = (price: number): number => Math.round(price * 100)
// === alt: formats with no decimals, then reads the number back
export const toCents = (price: number): number => Number((price * 100).toFixed(0))
// === wrong: refuses — every price is 0 cents
export const toCents = (price: number): number => 0
// === wrong: partial — rounds up, so a product a hair over gains a cent
export const toCents = (price: number): number => Math.ceil(price * 100)
// === wrong: partial — drops the fraction, so a product a hair under loses a cent
export const toCents = (price: number): number => Math.trunc(price * 100)
// === wrong: partial — rounds the dollars, then multiplies, so the float error comes back
export const toCents = (price: number): number => Number(price.toFixed(2)) * 100
// === wrong: partial — scales through a thousand before dividing, so some products still land a hair under
export const toCents = (price: number): number => Math.floor((price * 1000) / 10)
// <<<
