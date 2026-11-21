// >>> fix
const seen = new Set<string>()

/** The ids in first-seen order with repeats dropped, calling `each` once for every id kept. */
export function dedupe(ids: string[], each: (id: string) => void = () => {}): string[] {
  const out: string[] = []
// === fixed
/** The ids in first-seen order with repeats dropped, calling `each` once for every id kept. */
export function dedupe(ids: string[], each: (id: string) => void = () => {}): string[] {
  const seen = new Set<string>()
  const out: string[] = []
// === alt: a default parameter builds a fresh Set on every call
/** The ids in first-seen order with repeats dropped, calling `each` once for every id kept. */
export function dedupe(ids: string[], each: (id: string) => void = () => {}, seen = new Set<string>()): string[] {
  const out: string[] = []
// === wrong: refuses — keeps no ids
/** The ids in first-seen order with repeats dropped, calling `each` once for every id kept. */
export function dedupe(ids: string[], each: (id: string) => void = () => {}): string[] {
  const seen = new Set<string>(ids)
  const out: string[] = []
// === wrong: partial — clears the shared Set at the start, so a call made from the callback wipes the outer call's ids
const seen = new Set<string>()

/** The ids in first-seen order with repeats dropped, calling `each` once for every id kept. */
export function dedupe(ids: string[], each: (id: string) => void = () => {}): string[] {
  seen.clear()
  const out: string[] = []
// <<<
  for (const id of ids) {
    if (seen.has(id)) continue
    seen.add(id)
    each(id)
    out.push(id)
  }
  return out
}
