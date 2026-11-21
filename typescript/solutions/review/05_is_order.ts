type Order = { items: Array<{ sku: string; qty: number }> }

/** Whether `x` is an order: an object whose `items` is a list of objects, each with a text `sku` and an integer `qty`. */
export function isOrder(x: unknown): x is Order {
  if (typeof x !== "object" || x === null) return false
  const items = (x as { items?: unknown }).items
  return Array.isArray(items) && items.every((i) =>
    typeof i === "object" && i !== null &&
    typeof (i as { sku?: unknown }).sku === "string" &&
    Number.isInteger((i as { qty?: unknown }).qty))
}
