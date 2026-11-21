import { record } from "./stock.ts"

/** Adds `sku` and returns every sku added so far. */
export function add(sku: string): string[] {
  return record(sku)
}
