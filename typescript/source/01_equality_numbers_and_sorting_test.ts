/*
Look for: `==` against anything but `null`; a comparison with `NaN`; `Number` on text that may
be blank; `parseInt` handed straight to `map`; a price multiplied into cents and floored;
`toFixed` read as a rounding rule; `sort()` with no comparator.

Why it bites: none of these throw. `==` converts both sides before it compares, so a number, a
boolean or a list can equal a string. `NaN` equals nothing, itself included, so `x === NaN` is
always false and the branch under it never runs. `Number` reads blank text as 0 and accepts the
word for infinity, so a check for `NaN` alone lets both through. `map` calls its function with
the item and the item's index, and `parseInt` takes a second argument too: the radix. Most
decimal fractions have no exact binary form, so a product meant to be whole cents can land a
hair under the whole number, and rounding down takes a cent off. `toFixed` rounds the binary
value, not the decimal you wrote. With no comparator, `sort` compares numbers as text, and it
sorts the array in place.

Review habit: Read for what is missing. A validation names the inputs it rejects; ask which bad
inputs it never names. A function passed by name receives every argument `map` gives it, not
only the one you meant. A sort with no comparator is missing its rule, and a sort on the
caller's array is missing a copy.

A common mistake: swapping one check for its neighbour. `!value` treats 0 and false as blank,
just as `==` did. `Number.parseInt` is the same function as `parseInt`. Rounding the dollars
with `toFixed` before multiplying brings the float error back.

Read more: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Equality,
https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/parseInt,
https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/isFinite,
https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/sort
*/

import { expect, test } from "vitest"
import { __, runChecks, verdict } from "#koans"

test("Six comparisons, loose and strict, on values of every kind. What does each one give?", () => {
  const zero: unknown = 0
  const empty: unknown = ""
  const nothing: unknown = null
  const missing: unknown = undefined
  const notANumber: unknown = NaN
  const list: unknown = [1]
  const one: unknown = 1
  const zeroText: unknown = "0"
  const no: unknown = false
  const results = [zero == empty, nothing == missing, nothing === missing, notANumber === notANumber, list == one, zeroText == no]
  expect(results).toEqual(_a([true, true, false, false, true, true]))
})

test("Read koans/review/01_is_blank.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("01_is_blank.ts", _a(3))
})

test("Fix the bug in koans/review/01_is_blank.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "01_is_blank")
})

test("Read koans/review/01_parse_price.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("01_parse_price.ts", _a(4))
})

test("Fix the bug in koans/review/01_parse_price.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "01_parse_price")
})

test("parseInt reads five strings, then runs as a map callback. What comes out, and is Number.parseInt the same function?", () => {
  expect(["08", "0x1F", "1e3", "12px", ""].map((s) => parseInt(s))).toEqual(_a([8, 31, 1, 12, NaN]))
  expect(["1", "2", "3"].map(parseInt)).toEqual(_a([1, NaN, NaN]))
  expect(Number.parseInt === parseInt).toEqual(_a(true))
})

test("Read koans/review/01_parse_ids.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("01_parse_ids.ts", _a(2))
})

test("Fix the bug in koans/review/01_parse_ids.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "01_parse_ids")
})

test("Decimals are added, formatted, rounded and scaled to cents. What does each line give?", () => {
  expect(0.1 + 0.2).toEqual(_a(0.30000000000000004))
  expect([(1.005).toFixed(2), (2.5).toFixed(0), (0.5).toFixed(0)]).toEqual(_a(["1.00", "3", "1"]))
  expect([Math.round(2.5), Math.round(-2.5), Math.round(-0.4)]).toEqual(_a([3, -2, -0]))
  expect([19.99 * 100, 1.1 * 100]).toEqual(_a([1998.9999999999998, 110.00000000000001]))
})

test("Read koans/review/01_to_cents.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("01_to_cents.ts", _a(2))
})

test("Fix the bug in koans/review/01_to_cents.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "01_to_cents")
})

test("Read koans/review/01_rank.ts. Write \"fine\", or the line number of the bug.", async () => {
  verdict("01_rank.ts", _a("fine"))
  await runChecks(import.meta.url, "01_rank")
})

test("Numbers are sorted with and without a comparator, then mixed-case letters. What order comes out?", () => {
  expect([10, 9, 1, 100].sort()).toEqual(_a([1, 10, 100, 9]))
  expect([10, 9, 1, 100].sort((a, b) => a - b)).toEqual(_a([1, 9, 10, 100]))
  expect(["b", "a", "C"].sort()).toEqual(_a(["C", "a", "b"]))
})
