import { vi } from "vitest"

const ASYNC = "inZone takes a synchronous function"

const isThenable = (value: unknown): boolean =>
  (typeof value === "object" || typeof value === "function") &&
  value !== null &&
  typeof (value as { then?: unknown }).then === "function"

/** Runs fake timers until none is pending or `turns` timers have fired, then flushes one microtask turn. */
export async function drain(turns = 100): Promise<void> {
  for (let left = turns; left > 0 && vi.getTimerCount() > 0; left -= 1) {
    await vi.advanceTimersToNextTimerAsync()
  }
  await Promise.resolve()
}

/** Resolves on one fake `setTimeout(…, 0)`, after the microtasks already queued. */
export function later(): Promise<void> {
  return new Promise((resolve) => {
    setTimeout(resolve, 0)
  })
}

function restoreZone(zone: string | undefined): void {
  if (zone === undefined) delete process.env.TZ
  else process.env.TZ = zone
}

/** Runs a synchronous `run` with `TZ` set to `zone`, and restores the zone afterwards. */
export function inZone<T>(zone: string, run: () => T): T {
  if (run.constructor.name === "AsyncFunction") throw new TypeError(ASYNC)
  const before = process.env.TZ
  process.env.TZ = zone
  try {
    const result = run()
    if (isThenable(result)) throw new TypeError(ASYNC)
    return result
  } finally {
    restoreZone(before)
  }
}
