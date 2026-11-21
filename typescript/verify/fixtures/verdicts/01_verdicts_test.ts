import { expect, test } from "vitest"
import { __, verdict } from "#koans"

test("Read verify/fixtures/verdicts/review/cart.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("cart.ts", 4, "98faec1207,a55ade82bc", "35a0864754")
})

test("Read verify/fixtures/verdicts/review/fine.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("fine.ts", 2, "21b792efc7", "a6489df449")
})

test("What is one plus one?", () => {
  const total = 1 + 1
  expect(total).toEqual(__)
})

test("Read verify/fixtures/verdicts/review/cart.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("cart.ts", __, "98faec1207,a55ade82bc", "35a0864754")
})
