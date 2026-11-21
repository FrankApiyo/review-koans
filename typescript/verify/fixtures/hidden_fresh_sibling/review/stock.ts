const added: string[] = []

/** Records `sku` and returns every sku recorded so far. */
export function record(sku: string): string[] {
  added.push(sku)
  return [...added]
}
