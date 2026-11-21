import { afterAll, expect, test } from "vitest"

afterAll(() => {
  throw "cleanup failed"
})

test("Two is two.", () => {
  expect(2).toEqual(2)
})
