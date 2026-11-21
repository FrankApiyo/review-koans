import { afterAll, expect, test } from "vitest"

afterAll(() => {
  throw new RangeError("cleanup failed")
})

test("One is one.", () => {
  expect(1).toEqual(1)
})
