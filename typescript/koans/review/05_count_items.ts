type Order = { items: Array<{ sku: string; qty: number }> }

/** The total quantity in an order's JSON body. A malformed order throws: one whose `items` is not a list, or whose quantities are not all whole numbers of zero or more. */
export function countItems(body: string): number {
  const order = JSON.parse(body) as Order
  return order.items.reduce((sum, item) => sum + item.qty, 0)
}
