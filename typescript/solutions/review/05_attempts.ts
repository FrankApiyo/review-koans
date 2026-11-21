/** How many tries to make: the first try plus `opts.retries` retries, or plus 3 retries when `retries` is not given. */
export const attempts = (opts: { retries?: number }) => 1 + (opts.retries ?? 3)
