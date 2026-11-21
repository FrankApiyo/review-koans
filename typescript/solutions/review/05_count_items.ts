type Order = { items: Array<{ sku: string; qty: number }> }

/** The total quantity in an order's JSON body. A malformed order throws: one whose `items` is not a list, or whose quantities are not all whole numbers of zero or more. */
export function countItems(body: string): number {
  const data: unknown = JSON.parse(body)
  const items = typeof data === "object" && data !== null ? (data as { items?: unknown }).items : undefined
  if (!Array.isArray(items)) throw new TypeError("an order needs a list of items")
  for (const item of items) {
    const qty: unknown = item?.qty
    if (typeof qty !== "number" || !Number.isInteger(qty) || qty < 0) throw new TypeError("each quantity must be a whole number of zero or more")
  }
  const order = data as Order
  return order.items.reduce((sum, item) => sum + item.qty, 0)
}
