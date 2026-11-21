/*
Look for: a spread or `Object.assign` copy that is then changed below its top level; `push`,
`sort`, `reverse` or `splice` on an array the caller passed in; `fill` with an object or a
list; a JSON round trip used as a deep copy; a `Set`, `Map` or list declared at module level
and changed inside a function.

Why it bites: assigning or spreading an object copies references, not the values they point
at. A spread copies one level, so a nested list is still the original's list, and a push onto
the copy's list is a push onto the caller's. `sort` and `reverse` reorder the array in place
and return that same array. `fill` puts one object in every slot. JSON has no dates, sets or
`undefined`: a `Date` comes back as text, a `Set` as an empty object, and an `undefined` field
vanishes. A module is loaded once, so state at module level is shared by every call, including
a call made while another is still running. A default parameter's expression runs again on
every call that leaves the argument out.

Review habit: Ask what happens with two at once. Two copies of one object, two calls in a row,
a call made from inside another: for each value a function changes, ask who else holds it. If
the answer is the caller or an earlier call, the change leaks.

A common mistake: copying the outer object and calling it a copy. `Object.assign({}, x)` is
the same shallow copy as a spread, and pushing onto a fresh copy of a list that nothing keeps
changes nothing. Resetting shared state at the end of a call misses the call that throws;
resetting it at the start breaks a call nested inside another. In a trace, the line that
crashes is not always the line at fault: in the booking trace the date was lost at line 4,
where the booking was copied, and that line never appears in the stack.

Read more: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Spread_syntax,
https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/toSorted,
https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/stringify,
https://nodejs.org/docs/latest-v24.x/api/globals.html
*/

import { expect, test } from "vitest"
import { __, runChecks, trace, verdict } from "#koans"

test("A note is copied with a spread, then the copy's tags get one more. What does the original note hold?", () => {
  const note = { title: "draft", tags: ["x"] }
  const copy = { ...note, title: "final" }
  copy.tags.push("y")
  expect(note).toEqual(_a({ title: "draft", tags: ["x", "y"] }))
})

test("Read koans/review/02_add_item.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("02_add_item.ts", _a(4))
})

test("Fix the bug in koans/review/02_add_item.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "02_add_item")
})

test("Read koans/review/02_top_three.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("02_top_three.ts", _a(2))
})

test("Fix the bug in koans/review/02_top_three.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "02_top_three")
})

test("One array is filled with a single empty list, another gets a new list per slot. After a push into each first slot, what do they hold?", () => {
  const shared: string[][] = Array(3).fill([])
  shared[0].push("a")
  const separate: string[][] = Array.from({ length: 3 }, () => [])
  separate[0].push("a")
  expect([shared, separate]).toEqual(_a([[["a"], ["a"], ["a"]], [["a"], [], []]]))
})

test("Read koans/review/02_collect_errors.ts. Write \"fine\", or the line number of the bug.", async () => {
  verdict("02_collect_errors.ts", _a("fine"))
  await runChecks(import.meta.url, "02_collect_errors")
})

test("Read traces/02_booking.ts.trace. Name the error, then the file and line it came from.", () => {
  expect(trace.errorName("02_booking")).toEqual(_a("TypeError"))
  expect(trace.crashFrame("02_booking")).toEqual(_a(["traces/02_booking.ts", 8]))
})

test("Read koans/review/02_dedupe.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("02_dedupe.ts", _a(1))
})

test("Fix the bug in koans/review/02_dedupe.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "02_dedupe")
})

test("Read koans/review/02_mark_edited.ts. Write \"fine\", or the line number of the bug.", async () => {
  verdict("02_mark_edited.ts", _a("fine"))
  await runChecks(import.meta.url, "02_mark_edited")
})
