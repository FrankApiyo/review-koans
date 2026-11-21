import { AssertionError } from "node:assert"
import { vi } from "vitest"

export type Case = { kind: "twin" | "exploit"; label: string; run: (review: any) => unknown }

export type Settled<T> = { done: true; value: T } | { done: true; error: unknown } | { done: false }

const realSetImmediate = globalThis.setImmediate

/** One real event-loop turn: every queued microtask runs, and no clock is read. */
export const macrotask = (): Promise<void> => new Promise((resolve) => realSetImmediate(resolve))

export function twin(label: string, run: (review: any) => unknown): Case {
  return { kind: "twin", label, run }
}

export function exploit(label: string, run: (review: any) => unknown): Case {
  return { kind: "exploit", label, run }
}

async function turn(): Promise<void> {
  if (vi.isFakeTimers() && vi.getTimerCount() > 0) await vi.advanceTimersToNextTimerAsync()
  else await macrotask()
}

/** Waits at most `turns` turns for `value`, firing at most one fake timer per turn. */
export async function settle<T>(value: Promise<T>, turns = 100): Promise<Settled<T>> {
  let state: Settled<T> = { done: false }
  value.then(
    (result) => {
      state = { done: true, value: result }
    },
    (error: unknown) => {
      state = { done: true, error }
    },
  )
  for (let left = turns; left > 0 && !state.done; left -= 1) await turn()
  return state
}

const refused = (): AssertionError => new AssertionError({ message: "" })

const accepted = (error: unknown, types: Function[]): boolean =>
  types.length === 0 || types.some((type) => error instanceof type)

/** Passes when `value` rejects with one of `types` (any error when none is named) within `settle`'s turns. */
export async function rejects(value: Promise<unknown>, ...types: Function[]): Promise<void> {
  const outcome = await settle(value)
  if (!("error" in outcome) || !accepted(outcome.error, types)) throw refused()
}

/** Passes when `run` throws one of `types` (any error when none is named). */
export function throws(run: () => unknown, ...types: Function[]): void {
  try {
    run()
  } catch (error) {
    if (accepted(error, types)) return
    throw refused()
  }
  throw refused()
}
