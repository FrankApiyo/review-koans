/** Reads a price from text. Text that is blank or is not a finite number throws a RangeError. */
export function parsePrice(raw: string): number {
  const n = Number(raw)
  // >>> fix
  if (Number.isNaN(n)) throw new RangeError(`not a price: ${raw}`)
  // === fixed
  if (raw.trim() === "" || !Number.isFinite(n)) throw new RangeError(`not a price: ${raw}`)
  // === alt: checks the number first, then the blank text
  if (!Number.isFinite(n) || raw.trim() === "") throw new RangeError(`not a price: ${raw}`)
  // === wrong: refuses — every text throws
  throw new RangeError(`not a price: ${raw}`)
  // === wrong: partial — rejects infinity but not blank text, which reads as 0
  if (!Number.isFinite(n)) throw new RangeError(`not a price: ${raw}`)
  // === wrong: partial — rejects the empty string but not spaces or infinity
  if (raw === "" || Number.isNaN(n)) throw new RangeError(`not a price: ${raw}`)
  // === wrong: partial — rejects positive infinity only, so negative infinity gets through
  if (raw.trim() === "" || n === Infinity || Number.isNaN(n)) throw new RangeError(`not a price: ${raw}`)
  // === wrong: partial — reads the leading number, so trailing text is ignored
  if (!Number.isFinite(Number.parseFloat(raw))) throw new RangeError(`not a price: ${raw}`)
  // <<<
  return n
}
