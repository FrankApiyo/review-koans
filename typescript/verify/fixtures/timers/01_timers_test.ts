import { createRequire } from "node:module"
import * as nodeTimers from "node:timers"
import { setTimeout as nodeSetTimeout } from "node:timers"
import { setImmediate as immediatePromise, setTimeout as timeoutPromise } from "node:timers/promises"
import { afterAll, expect, test, vi } from "vitest"
import { drain, later } from "#koans"

afterAll(() => {
  if (vi.isFakeTimers()) throw new Error("fake timers outlived the koans")
})

test("A long timeout runs after drain.", async () => {
  const started = performance.now()
  let ran = false
  setTimeout(() => {
    ran = true
  }, 60_000)
  await drain()
  expect(ran).toBe(true)
  expect(performance.now() - started).toBeLessThan(1000)
})

test("Later resolves after microtasks queued before it.", async () => {
  const order: string[] = []
  queueMicrotask(() => order.push("before"))
  const waited = later().then(() => order.push("later"))
  void Promise.resolve().then(() => order.push("after"))
  await drain()
  await waited
  expect(order).toEqual(["before", "after", "later"])
})

test("Drain stops after its turns on a setInterval.", async () => {
  let ticks = 0
  setInterval(() => {
    ticks += 1
  }, 10)
  await drain(5)
  expect(ticks).toBe(5)
  await drain()
  expect(ticks).toBe(105)
})

test("A setTimeout imported from node:timers runs after drain.", async () => {
  const ran: string[] = []
  nodeSetTimeout(() => ran.push("named"), 60_000)
  nodeTimers.setTimeout(() => ran.push("namespace"), 60_000)
  const required: typeof nodeTimers = createRequire(import.meta.url)("node:timers")
  required.setTimeout(() => ran.push("required"), 60_000)
  const imported = await import("node:timers")
  imported.setTimeout(() => ran.push("dynamic"), 60_000)
  await drain()
  expect(ran).toEqual(["named", "namespace", "required", "dynamic"])
})

test("A promised timeout from node:timers/promises resolves after drain.", async () => {
  const started = performance.now()
  const timed = timeoutPromise(60_000, "timeout")
  const immediate = immediatePromise("immediate")
  await drain()
  expect(await timed).toBe("timeout")
  expect(await immediate).toBe("immediate")
  expect(performance.now() - started).toBeLessThan(1000)
})

test("A koan that leaves a timer pending.", () => {
  setTimeout(() => undefined, 60_000)
  expect(vi.getTimerCount()).toBe(1)
})

test("The next koan starts with no pending timers.", () => {
  expect(vi.isFakeTimers()).toBe(true)
  expect(vi.getTimerCount()).toBe(0)
})
