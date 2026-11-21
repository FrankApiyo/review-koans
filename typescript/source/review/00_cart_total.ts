/** Each line of a cart holds a quantity and a unit price in cents; the total is in cents. */
export function total(lines: { qty: number; unitCents: number }[]): number {
  // >>> guard
  return lines.reduce((sum, line) => sum + line.qty * line.unitCents, 0)
  // === wrong: partial — drops the qty factor
  return lines.reduce((sum, line) => sum + line.unitCents, 0)
  // <<<
}
