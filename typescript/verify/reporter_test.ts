import { expect, test } from "vitest"
import { messageLine } from "../support/reporter.ts"

test("a load error's line comes from the file's own name in the message", () => {
  expect(messageLine("[ koans/01_a_test.ts:5:1 ]", "01_a_test.ts")).toBe(5)
  expect(messageLine("01_a_test.ts:7:2", "01_a_test.ts")).toBe(7)
  expect(messageLine("\u001b[2m[\u001b[0m koans/01_a_test.ts:9:1", "01_a_test.ts")).toBe(9)
})

test("a longer file name that ends with the same text is not a match", () => {
  expect(messageLine("[ koans/x01_a_test.ts:5:1 ]", "01_a_test.ts")).toBeNull()
  expect(messageLine("no location here", "01_a_test.ts")).toBeNull()
})
