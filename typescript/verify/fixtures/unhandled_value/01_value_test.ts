import { expect, test } from "vitest"

test("One is one.", () => {
  void Promise.reject("stray value")
  expect(1).toEqual(1)
})
