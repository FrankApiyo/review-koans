import { expect, test } from "vitest"

test("One is one.", () => {
  void Promise.reject(new TypeError("stray"))
  expect(1).toEqual(1)
})
