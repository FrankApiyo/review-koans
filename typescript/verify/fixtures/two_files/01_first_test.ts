import { expect, test } from "vitest"
import { __ } from "#koans"

test("One is one.", () => {
  expect(1).toEqual(1)
})

test("What is two?", () => {
  expect(2).toEqual(__)
})
