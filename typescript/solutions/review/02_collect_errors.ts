/** Appends a line naming the record's id when it has no email, to `errors` or to a new list when none is given, and returns that list. */
export function collectErrors(record: { id: number; email?: string }, errors: string[] = []): string[] {
  if (!record.email) errors.push(`${record.id}: missing email`)
  return errors
}
