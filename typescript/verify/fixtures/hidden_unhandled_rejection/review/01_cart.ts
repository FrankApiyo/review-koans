/** Saves `order` to the warehouse and returns it. */
export function save(order: { id: number }, send: (order: { id: number }) => Promise<void>): { id: number } {
  send(order).then(() => undefined)
  return order
}
