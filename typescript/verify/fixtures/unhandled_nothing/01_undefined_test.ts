import { expect, test } from "vitest"

test("One is one.", () => {
  void Promise.reject(undefined)
  expect(1).toEqual(1)
})
