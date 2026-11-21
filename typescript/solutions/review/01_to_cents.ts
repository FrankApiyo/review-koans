/** A price in dollars, given to at most two decimal places, as a whole number of cents. */
export const toCents = (price: number): number => Math.round(price * 100)
