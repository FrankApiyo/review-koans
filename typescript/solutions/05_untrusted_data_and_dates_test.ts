/*
Look for: `JSON.parse` followed by `as` with no check in between; `?.` on one side of `===`
and something optional on the other; `||` giving a default to a number or a string; a month
number passed straight to a `Date`; a date-only string turned into a `Date`; `toISOString`
cut down to a day; a type guard that checks less than its type promises.

Why it bites: `as` is a promise to the compiler, not a check. At run time `JSON.parse` returns
whatever the sender wrote: a quantity sent as text turns a sum into string joining, and a
renamed key reads as `undefined`. `?.` gives `undefined` when anything on its left is missing,
and one missing value equals another. `||` replaces every falsy value, so `0` and `""` get the
default too; `??` replaces only `null` and `undefined`. A `Date` counts months from 0, and a
day past the end of a month rolls into the next one. A date-only string is read as midnight
UTC, while a date and time with no zone is read as local time. `toISOString` always writes
the UTC day, which for part of every day is not the local one.

Review habit: Ask who supplied the value. If it came from a request body, a file or another
service, nothing has checked it until this code does, whatever its declared type says. For a
date, also ask whose calendar it is read on: UTC's, or the zone the user lives in.

A common mistake: converting a value instead of checking it. `Number` and `parseInt` turn text
into numbers and `parseInt` drops a fraction, so malformed data is summed as if it were good.
`typeof` gives "object" for `null` and for arrays. Testing a date only east of UTC, where
midnight UTC is still the same calendar day. `toLocaleDateString` writes the day in a format
that changes with the machine's locale. In the greeting trace the crash is on line 9, but the
fault is line 4, where the parsed body was called a `User` without being checked.

Read more: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/parse,
https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Optional_chaining,
https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Nullish_coalescing,
https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/Date
*/

import { expect, test } from "vitest"
import { __, runChecks, trace, verdict } from "#koans"

test("Read koans/review/05_count_items.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("05_count_items.ts", 5, "350500392c,dd596460e1", "2f2098d6c9")
})

test("Fix the bug in koans/review/05_count_items.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "05_count_items")
})

test("Read koans/review/05_can_edit.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("05_can_edit.ts", 3, "6977d9c23b", "41ad8fddd3")
})

test("Fix the bug in koans/review/05_can_edit.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "05_can_edit")
})

test("Read koans/review/05_attempts.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("05_attempts.ts", 2, "902f70e9c2", "c1d58cd19f")
})

test("Fix the bug in koans/review/05_attempts.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "05_attempts")
})

test("A date on the last day of January has its month set to February. Which month index and day does it land on?", () => {
  const d = new Date(2026, 0, 31)
  d.setMonth(1)
  expect([d.getMonth(), d.getDate()]).toEqual([2, 3])
})

test("Read koans/review/05_due_date.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("05_due_date.ts", 4, "a46affa478", "7c931eab6c")
})

test("Fix the bug in koans/review/05_due_date.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "05_due_date")
})

test("With TZ pinned to America/New_York, one day is read as a bare date and as a local midnight. What are the zone and each day of the month?", () => {
  const zone = process.env.TZ
  const bare = new Date("2026-03-15").getDate()
  const midnight = new Date("2026-03-15T00:00").getDate()
  expect([zone, bare, midnight]).toEqual(["America/New_York", 14, 15])
})

test("Read traces/05_greeting.ts.trace. Name the error, then the file and line it came from.", () => {
  expect(trace.errorName("05_greeting")).toEqual("TypeError")
  expect(trace.crashFrame("05_greeting")).toEqual(["traces/05_greeting.ts", 9])
})

test("Read koans/review/05_is_order.ts. Write \"fine\", or the line number of the bug.", async () => {
  verdict("05_is_order.ts", "fine", "ba76d7bfeb", "dc5745b994")
  await runChecks(import.meta.url, "05_is_order")
})

test("Read koans/review/05_day_key.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("05_day_key.ts", 2, "8681ce978e", "77c48b9c63")
})

test("Fix the bug in koans/review/05_day_key.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "05_day_key")
})
