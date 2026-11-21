import { fileURLToPath } from "node:url"
import { afterAll, beforeAll, expect, test } from "vitest"
import { crashFrame, errorName, exitCode, frames, read, stdout } from "../support/trace.ts"

const FIXTURES = fileURLToPath(new URL("fixtures", import.meta.url))
const started = process.cwd()

beforeAll(() => process.chdir(FIXTURES))
afterAll(() => process.chdir(started))

test("read returns the whole capture", () => {
  expect(read("boom").startsWith("exit 1\n--- stdout\nreporting\n--- stderr\n")).toBe(true)
  expect(read("boom").endsWith("Node.js v25.9.0\n")).toBe(true)
})

test("stdout is what the program printed before it crashed", () => {
  expect(stdout("unhandled")).toBe("order o-17 complete\n")
  expect(stdout("boom")).toBe("reporting\n")
})

test("exitCode is the process exit status", () => {
  expect(exitCode("boom")).toBe(1)
  expect(exitCode("unhandled")).toBe(1)
})

test("errorName is the name on the first error line of stderr", () => {
  expect(errorName("boom")).toBe("TypeError")
  expect(errorName("unhandled")).toBe("Error")
})

test("frames are the course frames in printed order without columns", () => {
  expect(frames("boom")).toEqual([
    ["traces/boom.ts", 2],
    ["traces/boom.ts", 7],
    ["traces/boom.ts", 11],
  ])
  expect(frames("unhandled")).toEqual([["traces/unhandled.ts", 4]])
})

test("crashFrame is the innermost course frame", () => {
  expect(crashFrame("boom")).toEqual(["traces/boom.ts", 2])
  expect(crashFrame("unhandled")).toEqual(["traces/unhandled.ts", 4])
})
