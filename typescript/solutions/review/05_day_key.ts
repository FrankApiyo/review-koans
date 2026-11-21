/** The local calendar day of `now`, as `YYYY-MM-DD`. */
export const dayKey = (now: Date): string => `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`
