/** Settings that `reload` replaces in place; `getTimeout` gives the timeout in force now. */
let config = { timeout: 5 }
let { timeout } = config

export function reload(next: { timeout: number }) { Object.assign(config, next) }
export function getTimeout() { return timeout }
