/*
Look for: an async callback passed to `forEach`, `filter` or `map` whose promise nobody awaits;
a promise used as a boolean or compared with `false`; a promise returned from inside a `try`
without `await`; `Promise.all` where the caller wants to hear about each item; a promise started
with `void`, or with no `await` and no `.catch`; steps that must run in order started all at once.

Why it bites: an async function runs until its first `await`, then hands its caller a promise,
and the caller carries on. Work queued as a microtask (a `then` callback, `queueMicrotask`, the
rest of an async function after an `await`) runs before the next timer callback. `forEach`
ignores the promise its callback returns, and `filter` treats it as a yes, because a promise is
always truthy, so `!promise` is always false. A `try` only catches what fails while it runs: a
promise returned without `await` rejects after the function has left the `try`. `Promise.all`
rejects with the first failure and drops every other result. A rejection nobody handles ends
the Node process, after whatever it already printed. Awaiting one step at a time is right when
each step needs the one before it.

Review habit: Ask what happens on crash. For each promise a line starts, ask who waits for it
and who hears if it rejects. If nobody does, the function reports success before the work is
done, and the failure arrives later, with the caller gone from the stack.

A common mistake: putting `await` in front of something that is not a promise, such as an array
of promises or the result of `forEach`, which waits for nothing; catching each failure as `null`,
which reports a failure as a success; wrapping the whole batch in one `try`, which makes one
failure count for all. In the order trace the stack shows only the line that threw; the fault
is line 9, which started the promise and never waited for it, and line 9 is not in the stack.

Read more: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/await,
https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/forEach,
https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/allSettled,
https://nodejs.org/docs/latest-v24.x/api/process.html
*/

import { expect, test } from "vitest"
import { __, drain, runChecks, trace, verdict } from "#koans"

test("A timer, a then callback, a queued microtask and an async function each push a letter. In what order do the letters land?", async () => {
  const log: string[] = []
  log.push("A")
  setTimeout(() => log.push("B"), 0)
  Promise.resolve().then(() => log.push("C"))
  queueMicrotask(() => log.push("D"))
  ;(async () => {
    log.push("E")
    await null
    log.push("F")
  })()
  log.push("G")
  await drain()
  expect(log.join(" ")).toEqual("A E G C D F B")
})

test("An async function awaits another async function while the caller carries on. In what order do the entries land?", async () => {
  const log: string[] = []
  async function b() {
    log.push("b")
  }
  async function a() {
    log.push("a1")
    await b()
    log.push("a2")
  }
  a()
  log.push("main")
  await Promise.resolve()
  expect(log.join(" ")).toEqual("a1 b main a2")
})

test("Read koans/review/04_save_all.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("04_save_all.ts", 3, "fb3946d3ed", "789da7a7cb")
})

test("Fix the bug in koans/review/04_save_all.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "04_save_all")
})

test("Read koans/review/04_remove_note.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("04_remove_note.ts", 6, "3e7bee5e95", "71143f1dba")
})

test("Fix the bug in koans/review/04_remove_note.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "04_remove_note")
})

test("Read koans/review/04_send_all.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("04_send_all.ts", 5, "27e4fcb7d7,2b5bd97998", "07794e3fe1")
})

test("Fix the bug in koans/review/04_send_all.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "04_send_all")
})

test("Read traces/04_complete_order.ts.trace. What did the program print before it crashed?", () => {
  expect(trace.stdout("04_complete_order")).toEqual("order o-17 complete\n")
})

test("Read traces/04_complete_order.ts.trace. Name the error, then the file and line it came from.", () => {
  expect(trace.errorName("04_complete_order")).toEqual("Error")
  expect(trace.crashFrame("04_complete_order")).toEqual(["traces/04_complete_order.ts", 4])
})

test("Read koans/review/04_find_user.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("04_find_user.ts", 4, "6212f4c591", "7bf3537499")
})

test("Fix the bug in koans/review/04_find_user.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "04_find_user")
})

test("Read koans/review/04_migrate.ts. Write \"fine\", or the line number of the bug.", async () => {
  verdict("04_migrate.ts", "fine", "202d75d9fa", "04ed93169e")
  await runChecks(import.meta.url, "04_migrate")
})

test("Read koans/review/04_active_users.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("04_active_users.ts", 3, "868cc33fe5", "466bc7c52d")
})

test("Fix the bug in koans/review/04_active_users.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "04_active_users")
})
