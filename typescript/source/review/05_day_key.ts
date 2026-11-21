/** The local calendar day of `now`, as `YYYY-MM-DD`. */
// >>> fix
export const dayKey = (now: Date): string => now.toISOString().slice(0, 10)
// === fixed
export const dayKey = (now: Date): string => `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`
// === alt: shifts the moment by the local offset, then takes the ISO day
export const dayKey = (now: Date): string => new Date(now.getTime() - now.getTimezoneOffset() * 60_000).toISOString().slice(0, 10)
// === alt: pads each local part in turn and joins them
export const dayKey = (now: Date): string => [now.getFullYear(), now.getMonth() + 1, now.getDate()].map((n) => String(n).padStart(2, "0")).join("-")
// === wrong: refuses — gives no day at all
export const dayKey = (now: Date): string => ""
// === wrong: partial — local getters, but the month counts from 0 and nothing is padded
export const dayKey = (now: Date): string => `${now.getFullYear()}-${now.getMonth()}-${now.getDate()}`
// === wrong: partial — the UTC getters give the UTC day, not the local one
export const dayKey = (now: Date): string => `${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, "0")}-${String(now.getUTCDate()).padStart(2, "0")}`
// <<<
