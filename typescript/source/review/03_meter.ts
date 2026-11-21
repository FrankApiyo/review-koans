/** A running total; `add` adds one number to it. */
export const meter = { total: 0, add(n: number) { this.total += n } }

/** Adds each number to the meter's total, in order. */
export function addAll(ns: number[]): void {
  // >>> fix
  ns.forEach(meter.add)
  // === fixed
  ns.forEach((n) => meter.add(n))
  // === alt: binds the method to the meter before handing it over
  ns.forEach(meter.add.bind(meter))
  // === alt: passes the meter as forEach's this argument
  ns.forEach(meter.add, meter)
  // === alt: calls the method on the meter in a loop
  for (const n of ns) meter.add(n)
  // === wrong: refuses — throws for every list, even an empty one
  throw new RangeError("cannot add these numbers")
  // === wrong: partial — passes the list as this, so the numbers are added to the list, not the meter
  ns.forEach(meter.add, ns)
  // === wrong: partial — a bare name for the method still calls it without its object
  const add = meter.add
  ns.forEach((n) => add(n))
  // === wrong: partial — sets the total to this list's sum instead of adding to it
  meter.total = ns.reduce((sum, n) => sum + n, 0)
  // <<<
}
