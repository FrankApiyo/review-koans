import { createRequire, syncBuiltinESMExports } from "node:module"
import { promisify } from "node:util"

type Callable = (...args: unknown[]) => unknown
type TimerName = "setTimeout" | "clearTimeout" | "setInterval" | "clearInterval" | "setImmediate" | "clearImmediate"
type Options = { signal?: AbortSignal } | undefined

const TIMERS: readonly TimerName[] = [
  "setTimeout",
  "clearTimeout",
  "setInterval",
  "clearInterval",
  "setImmediate",
  "clearImmediate",
]

const require = createRequire(import.meta.url)
const REAL_SET_TIMEOUT = globalThis.setTimeout
const state = { installed: false }

const faking = (): boolean => globalThis.setTimeout !== REAL_SET_TIMEOUT

function aborted(signal: AbortSignal): Error {
  return Object.assign(new Error("The operation was aborted"), {
    name: "AbortError",
    code: "ABORT_ERR",
    cause: signal.reason,
  })
}

function settleOn<T>(schedule: (done: () => void) => unknown, cancel: (id: unknown) => void, value: T, options: Options): Promise<T> {
  const signal = options?.signal
  return new Promise<T>((resolve, reject) => {
    if (signal?.aborted) return reject(aborted(signal))
    const onAbort = (): void => {
      cancel(id)
      reject(aborted(signal as AbortSignal))
    }
    const id = schedule(() => {
      signal?.removeEventListener("abort", onAbort)
      resolve(value)
    })
    signal?.addEventListener("abort", onAbort, { once: true })
  })
}

function fakeTimeout<T>(delay?: number, value?: T, options?: Options): Promise<T | undefined> {
  const schedule = (done: () => void): unknown => globalThis.setTimeout(done, delay)
  const cancel = (id: unknown): void => globalThis.clearTimeout(id as NodeJS.Timeout)
  return settleOn(schedule, cancel, value, options)
}

function fakeImmediate<T>(value?: T, options?: Options): Promise<T | undefined> {
  const schedule = (done: () => void): unknown => globalThis.setImmediate(done)
  const cancel = (id: unknown): void => globalThis.clearImmediate(id as NodeJS.Immediate)
  return settleOn(schedule, cancel, value, options)
}

function whenFaking(real: Callable, fake: Callable): Callable {
  return (...args: unknown[]) => (faking() ? fake(...args) : real(...args))
}

function mirrorTimers(timers: Record<string, unknown>, promised: Callable): void {
  for (const name of TIMERS) {
    const mirrored = (...args: unknown[]): unknown => (globalThis[name] as Callable)(...args)
    if (name === "setTimeout") Object.defineProperty(mirrored, promisify.custom, { value: promised })
    timers[name] = mirrored
  }
}

function mirrorPromises(promises: Record<string, Callable>, scheduler: Record<string, Callable>): void {
  const refuseInterval = (): never => {
    throw new Error("koans run under fake timers: use setInterval, not node:timers/promises")
  }
  const { setTimeout, setImmediate, setInterval } = promises
  const { wait, yield: yieldNow } = scheduler
  promises.setTimeout = whenFaking(setTimeout as Callable, fakeTimeout as Callable)
  promises.setImmediate = whenFaking(setImmediate as Callable, fakeImmediate as Callable)
  promises.setInterval = whenFaking(setInterval as Callable, refuseInterval)
  scheduler.wait = whenFaking(wait as Callable, (delay, options) => fakeTimeout(delay as number, undefined, options as Options))
  scheduler.yield = whenFaking(yieldNow as Callable, () => fakeImmediate())
}

/**
 * Makes node:timers and node:timers/promises follow the global timers, so a
 * timer imported from them is faked whenever the globals are.
 */
export function mirrorNodeTimers(): void {
  if (state.installed) return
  const promises = require("node:timers/promises") as Record<string, Callable> & { scheduler: Record<string, Callable> }
  mirrorPromises(promises, promises.scheduler)
  mirrorTimers(require("node:timers") as Record<string, unknown>, promises.setTimeout as Callable)
  syncBuiltinESMExports()
  state.installed = true
}
