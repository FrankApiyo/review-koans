import { expect, test } from "vitest"

test("Two is two.", () => {
  void Promise.reject(null)
  expect(2).toEqual(2)
})
