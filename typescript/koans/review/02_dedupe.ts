const seen = new Set<string>()

/** The ids in first-seen order with repeats dropped, calling `each` once for every id kept. */
export function dedupe(ids: string[], each: (id: string) => void = () => {}): string[] {
  const out: string[] = []
  for (const id of ids) {
    if (seen.has(id)) continue
    seen.add(id)
    each(id)
    out.push(id)
  }
  return out
}
