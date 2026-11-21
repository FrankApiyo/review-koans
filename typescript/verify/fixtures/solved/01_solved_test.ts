import { expect, test } from "vitest"
import { verdict } from "#koans"

test("Read verify/fixtures/solved/review/cart.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("cart.ts", 4, "98faec1207,a55ade82bc", "35a0864754")
})

test("Read verify/fixtures/solved/review/fine.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("fine.ts", "fine", "21b792efc7", "a6489df449")
})

test("What is one plus one?", () => {
  expect(1 + 1).toEqual(2)
})
