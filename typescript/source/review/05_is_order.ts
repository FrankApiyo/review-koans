type Order = { items: Array<{ sku: string; qty: number }> }

/** Whether `x` is an order: an object whose `items` is a list of objects, each with a text `sku` and an integer `qty`. */
// >>> guard
export function isOrder(x: unknown): x is Order {
  if (typeof x !== "object" || x === null) return false
  const items = (x as { items?: unknown }).items
  return Array.isArray(items) && items.every((i) =>
    typeof i === "object" && i !== null &&
    typeof (i as { sku?: unknown }).sku === "string" &&
    Number.isInteger((i as { qty?: unknown }).qty))
}
// === wrong: partial — typeof gives "object" for null, so null is read as if it had items
export function isOrder(x: unknown): x is Order {
  if (typeof x !== "object") return false
  const items = (x as { items?: unknown }).items
  return Array.isArray(items) && items.every((i) =>
    typeof i === "object" && i !== null &&
    typeof (i as { sku?: unknown }).sku === "string" &&
    Number.isInteger((i as { qty?: unknown }).qty))
}
// === wrong: partial — any number passes as a quantity, fractions included
export function isOrder(x: unknown): x is Order {
  if (typeof x !== "object" || x === null) return false
  const items = (x as { items?: unknown }).items
  return Array.isArray(items) && items.every((i) =>
    typeof i === "object" && i !== null &&
    typeof (i as { sku?: unknown }).sku === "string" &&
    typeof (i as { qty?: unknown }).qty === "number")
}
// === wrong: partial — a null item is read as if it had a sku
export function isOrder(x: unknown): x is Order {
  if (typeof x !== "object" || x === null) return false
  const items = (x as { items?: unknown }).items
  return Array.isArray(items) && items.every((i) =>
    typeof i === "object" &&
    typeof (i as { sku?: unknown }).sku === "string" &&
    Number.isInteger((i as { qty?: unknown }).qty))
}
// <<<
