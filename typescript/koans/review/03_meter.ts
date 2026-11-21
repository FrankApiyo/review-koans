/** A running total; `add` adds one number to it. */
export const meter = { total: 0, add(n: number) { this.total += n } }

/** Adds each number to the meter's total, in order. */
export function addAll(ns: number[]): void {
  ns.forEach(meter.add)
}
