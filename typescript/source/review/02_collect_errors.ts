/** Appends a line naming the record's id when it has no email, to `errors` or to a new list when none is given, and returns that list. */
// >>> guard
export function collectErrors(record: { id: number; email?: string }, errors: string[] = []): string[] {
  if (!record.email) errors.push(`${record.id}: missing email`)
  return errors
}
// === wrong: partial — every call without a list shares one module-level list
const noErrors: string[] = []
export function collectErrors(record: { id: number; email?: string }, errors: string[] = noErrors): string[] {
  if (!record.email) errors.push(`${record.id}: missing email`)
  return errors
}
// === wrong: partial — copies the caller's list first, so the caller's list is never appended to
export function collectErrors(record: { id: number; email?: string }, errors: string[] = []): string[] {
  errors = [...errors]
  if (!record.email) errors.push(`${record.id}: missing email`)
  return errors
}
// <<<
