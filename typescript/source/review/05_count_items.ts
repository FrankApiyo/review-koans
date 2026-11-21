type Order = { items: Array<{ sku: string; qty: number }> }

/** The total quantity in an order's JSON body. A malformed order throws: one whose `items` is not a list, or whose quantities are not all whole numbers of zero or more. */
export function countItems(body: string): number {
  // >>> fix
  const order = JSON.parse(body) as Order
  return order.items.reduce((sum, item) => sum + item.qty, 0)
  // === fixed
  const data: unknown = JSON.parse(body)
  const items = typeof data === "object" && data !== null ? (data as { items?: unknown }).items : undefined
  if (!Array.isArray(items)) throw new TypeError("an order needs a list of items")
  for (const item of items) {
    const qty: unknown = item?.qty
    if (typeof qty !== "number" || !Number.isInteger(qty) || qty < 0) throw new TypeError("each quantity must be a whole number of zero or more")
  }
  const order = data as Order
  return order.items.reduce((sum, item) => sum + item.qty, 0)
  // === alt: checks the parsed body with a type guard before treating it as an order
  const isOrder = (x: any): x is Order => Array.isArray(x?.items) && x.items.every((i: any) => Number.isInteger(i?.qty) && i.qty >= 0)
  const order: unknown = JSON.parse(body)
  if (!isOrder(order)) throw new TypeError("not an order")
  return order.items.reduce((sum, item) => sum + item.qty, 0)
  // === alt: checks each quantity as it adds it
  const data: unknown = JSON.parse(body)
  const items = (data as { items?: unknown } | null)?.items
  if (!Array.isArray(items)) throw new TypeError("an order needs a list of items")
  return items.reduce((sum: number, item) => {
    if (!Number.isSafeInteger(item?.qty) || item.qty < 0) throw new TypeError("bad quantity")
    return sum + item.qty
  }, 0)
  // === wrong: refuses — throws for every body, even a well-formed order
  throw new TypeError("not an order")
  // === wrong: partial — converts each quantity to a number, so text, fractions and negatives are summed instead of refused
  const order = JSON.parse(body) as Order
  return order.items.reduce((sum, item) => sum + Number(item.qty), 0)
  // === wrong: partial — reads a whole number out of each quantity, so text and fractions are summed instead of refused
  const order = JSON.parse(body) as Order
  return order.items.reduce((sum, item) => sum + parseInt(String(item.qty), 10), 0)
  // === wrong: partial — checks only that each quantity is a number, so fractions and negatives get through
  const order = JSON.parse(body) as Order
  if (!order.items.every((item) => typeof item.qty === "number")) throw new TypeError("quantities must be numbers")
  return order.items.reduce((sum, item) => sum + item.qty, 0)
  // <<<
}
