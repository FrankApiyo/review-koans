/*
Look for: a method handed over by name, to `map`, `forEach` or an event emitter, or pulled off
its object by destructuring; `bind` called once where a listener is added and again where it is
removed; `var` in a loop whose body makes functions; a value copied out of an object once and
read long after.

Why it bites: a method's `this` is chosen by the call, not by the line that defines it.
`obj.method()` passes `obj`. A bare call passes `undefined` in a module, so reading through
`this` throws. `EventEmitter` calls its listeners with the emitter as `this`, so the method
writes to the emitter and nothing throws at all. An arrow function has no `this` of its own:
it keeps the `this` of the code around it, so an arrow class field stays tied to its instance.
Every `bind` call makes a new function, and `off` removes only the very function `on` was
given. `var` makes one variable for the whole function, so every function made in the loop
reads its last value; `let` in a loop head makes a fresh one each pass. Destructuring copies
the value as it is at that moment, and later changes to the object never reach the copy.

Review habit: Ask who supplied the value. For `this`, the caller supplies it, so find the call
that runs the function, not the line that defines it. For a value a function reads later, ask
which variable it reads and who last wrote to it.

A common mistake: binding again where the listener comes off, which removes a function that
was never added. Copying the loop item into another `var` still shares one variable. Replacing
the settings object does nothing for a copy taken from the old one. In a trace, the line that
throws reads `this`; the line at fault is the one that pulled the method off its object, which
in the billing trace is line 14, and that line never appears in the stack.

Read more: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/this,
https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/bind,
https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/let,
https://nodejs.org/docs/latest-v24.x/api/events.html
*/

import { expect, test } from "vitest"
import { __, runChecks, trace, verdict } from "#koans"

test("Read traces/03_billing.ts.trace. Name the error, then the file and line it came from.", () => {
  expect(trace.errorName("03_billing")).toEqual("TypeError")
  expect(trace.crashFrame("03_billing")).toEqual(["traces/03_billing.ts", 9])
})

test("Read koans/review/03_tick_counter.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("03_tick_counter.ts", 8, "0abf44eac1,2af360d5ae,4b6923d21d", "242799f9ba")
})

test("Fix the bug in koans/review/03_tick_counter.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "03_tick_counter")
})

test("Two loops push functions that return the loop counter, one with var and one with let. What do they return?", () => {
  const withVar: Array<() => number> = []
  for (var i = 0; i < 3; i++) withVar.push(() => i)
  const withLet: Array<() => number> = []
  for (let j = 0; j < 3; j++) withLet.push(() => j)
  expect([withVar.map((f) => f()), withLet.map((f) => f())]).toEqual([[3, 3, 3], [0, 1, 2]])
})

test("Read koans/review/03_queue_jobs.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("03_queue_jobs.ts", 4, "dcc12260ea", "1c1e8b9312")
})

test("Fix the bug in koans/review/03_queue_jobs.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "03_queue_jobs")
})

test("Read koans/review/03_meter.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("03_meter.ts", 6, "f685413183", "1720172171")
})

test("Fix the bug in koans/review/03_meter.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "03_meter")
})

test("Read koans/review/03_labeler.ts. Write \"fine\", or the line number of the bug.", async () => {
  verdict("03_labeler.ts", "fine", "4ac8b41557", "1ea4236590")
  await runChecks(import.meta.url, "03_labeler")
})

test("A counter hands out an increment, a getter and a snapshot of the same variable. What does each give?", () => {
  function makeCounter() {
    let n = 0
    return {
      inc: () => ++n,
      get value() {
        return n
      },
      snapshot: n,
    }
  }
  const c = makeCounter()
  expect([c.inc(), c.inc(), c.value, c.snapshot]).toEqual([1, 2, 2, 0])
})

test("Read koans/review/03_timeout.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("03_timeout.ts", 3, "02becb8761,2cb735edf8,999f3da1c8,9bcbc36479", "8241af7c00")
})

test("Fix the bug in koans/review/03_timeout.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "03_timeout")
})
