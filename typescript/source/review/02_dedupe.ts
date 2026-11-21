// >>> fix
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
// === fixed
/** The ids in first-seen order with repeats dropped, calling `each` once for every id kept. */
export function dedupe(ids: string[], each: (id: string) => void = () => {}): string[] {
  const seen = new Set<string>()
  const out: string[] = []
  for (const id of ids) {
    if (seen.has(id)) continue
    seen.add(id)
    each(id)
    out.push(id)
  }
// === alt: walks a Set built from this call's ids
/** The ids in first-seen order with repeats dropped, calling `each` once for every id kept. */
export function dedupe(ids: string[], each: (id: string) => void = () => {}): string[] {
  const out: string[] = []
  for (const id of new Set(ids)) {
    each(id)
    out.push(id)
  }
// === wrong: refuses — keeps no ids
/** The ids in first-seen order with repeats dropped, calling `each` once for every id kept. */
export function dedupe(ids: string[], each: (id: string) => void = () => {}): string[] {
  const out: string[] = []
// === wrong: partial — clears the shared Set at the end, which a throwing callback skips
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
  seen.clear()
// === wrong: partial — clears the shared Set at the start, so a call made from the callback wipes the outer call's ids
const seen = new Set<string>()

/** The ids in first-seen order with repeats dropped, calling `each` once for every id kept. */
export function dedupe(ids: string[], each: (id: string) => void = () => {}): string[] {
  seen.clear()
  const out: string[] = []
  for (const id of ids) {
    if (seen.has(id)) continue
    seen.add(id)
    each(id)
    out.push(id)
  }
// === wrong: partial — clears the shared Set in a finally, so a call made from the callback still sees the outer call's ids
const seen = new Set<string>()

/** The ids in first-seen order with repeats dropped, calling `each` once for every id kept. */
export function dedupe(ids: string[], each: (id: string) => void = () => {}): string[] {
  const out: string[] = []
  try {
    for (const id of ids) {
      if (seen.has(id)) continue
      seen.add(id)
      each(id)
      out.push(id)
    }
  } finally {
    seen.clear()
  }
// <<<
  return out
}
