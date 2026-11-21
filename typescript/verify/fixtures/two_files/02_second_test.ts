import { expect, test } from "vitest"
import { __ } from "#koans"

test("What is three?", () => {
  expect(3).toEqual(__)
})
