/** The local calendar day of `now`, as `YYYY-MM-DD`. */
export const dayKey = (now: Date): string => now.toISOString().slice(0, 10)
