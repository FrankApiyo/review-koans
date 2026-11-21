function itemCount(order: { items: string[] }) {
  return order.items.length
}

console.log(itemCount({ items: ["pear", "fig"] }))
console.log(itemCount(JSON.parse("{}")))
