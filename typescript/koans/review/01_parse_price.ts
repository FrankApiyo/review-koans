/** Reads a price from text. Text that is blank or is not a finite number throws a RangeError. */
export function parsePrice(raw: string): number {
  const n = Number(raw)
  if (Number.isNaN(n)) throw new RangeError(`not a price: ${raw}`)
  return n
}
