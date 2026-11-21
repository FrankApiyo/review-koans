/** Settings that `reload` replaces in place; `getTimeout` gives the timeout in force now. */
const config = { timeout: 5 }

export function reload(next: { timeout: number }) { Object.assign(config, next) }
export function getTimeout() { return config.timeout }
