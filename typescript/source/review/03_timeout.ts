/** Settings that `reload` replaces in place; `getTimeout` gives the timeout in force now. */
let config = { timeout: 5 }
// >>> fix
let { timeout } = config

export function reload(next: { timeout: number }) { Object.assign(config, next) }
export function getTimeout() { return timeout }
// === fixed
export function reload(next: { timeout: number }) { Object.assign(config, next) }
export function getTimeout() { return config.timeout }
// === alt: updates the copied timeout whenever the settings are reloaded
let { timeout } = config

export function reload(next: { timeout: number }) { Object.assign(config, next); timeout = next.timeout }
export function getTimeout() { return timeout }
// === wrong: refuses — has no timeout until the first reload
let timeout: number | undefined

export function reload(next: { timeout: number }) { Object.assign(config, next); timeout = next.timeout }
export function getTimeout() { return timeout }
// === wrong: partial — replacing the settings object leaves the copied timeout just as stale
let { timeout } = config

export function reload(next: { timeout: number }) { config = { ...config, ...next } }
export function getTimeout() { return timeout }
// === wrong: partial — copies the timeout again before the reload changes it, so it trails one reload behind
let { timeout } = config

export function reload(next: { timeout: number }) { ({ timeout } = config); Object.assign(config, next) }
export function getTimeout() { return timeout }
// <<<
