/** How many tries to make: the first try plus `opts.retries` retries, or plus 3 retries when `retries` is not given. */
// >>> fix
export const attempts = (opts: { retries?: number }) => 1 + (opts.retries || 3)
// === fixed
export const attempts = (opts: { retries?: number }) => 1 + (opts.retries ?? 3)
// === alt: uses 3 only when retries is undefined
export const attempts = (opts: { retries?: number }) => 1 + (opts.retries === undefined ? 3 : opts.retries)
// === wrong: refuses — always one try
export const attempts = (opts: { retries?: number }) => 1
// === wrong: partial — a truthiness test still treats zero retries as not given
export const attempts = (opts: { retries?: number }) => 1 + (opts.retries ? opts.retries : 3)
// === wrong: partial — zero still falls through to the default of 3
export const attempts = (opts: { retries?: number }) => 1 + ((opts.retries || 0) || 3)
// <<<
