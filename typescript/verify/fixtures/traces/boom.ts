function itemCount(order: { items: string[] }): number {
  return order.items.length
}

function report(raw: string): string {
  const order = JSON.parse(raw)
  return `items: ${itemCount(order)}`
}

console.log("reporting")
console.log(report("{}"))
