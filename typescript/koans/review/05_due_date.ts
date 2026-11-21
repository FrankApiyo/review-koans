/** The due date for a `YYYY-MM-DD` day, as a `Date` on that calendar day in local time. */
export function dueDate(day: string): Date {
  const [y, m, d] = day.split("-").map(Number)
  return new Date(y, m, d)
}
