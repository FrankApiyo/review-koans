/** The due date for a `YYYY-MM-DD` day, as a `Date` on that calendar day in local time. */
export function dueDate(day: string): Date {
  const [y, m, d] = day.split("-").map(Number)
  // >>> fix
  return new Date(y, m, d)
  // === fixed
  return new Date(y, m - 1, d)
  // === alt: parses the day as a local date-time
  return new Date(`${day}T00:00`)
  // === wrong: refuses — gives the same moment for every day
  return new Date(0)
  // === wrong: partial — a date-only string is read as midnight UTC, which is the day before west of UTC
  return new Date(day)
  // === wrong: partial — builds midnight UTC, which is the day before west of UTC
  return new Date(Date.UTC(y, m - 1, d))
  // <<<
}
