async function sendReceipt(email: string): Promise<void> {
  await Promise.resolve()
  if (!email.includes("@")) {
    throw new Error(`invalid recipient: ${email}`)
  }
}

function completeOrder(orderId: string, email: string): string {
  void sendReceipt(email)
  return `order ${orderId} complete`
}

console.log(completeOrder("o-17", "ann.example.com"))
