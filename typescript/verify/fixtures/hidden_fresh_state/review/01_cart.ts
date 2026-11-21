const added: string[] = []

/** Records `sku` and returns every sku recorded so far. */
export function add(sku: string): string[] {
  added.push(sku)
  return [...added]
}
