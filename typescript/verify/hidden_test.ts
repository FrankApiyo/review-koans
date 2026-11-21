import { AssertionError } from "node:assert"
import { mkdirSync, mkdtempSync, realpathSync, writeFileSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { afterEach, expect, test, vi } from "vitest"
import { rejects, settle, throws } from "../support/checks.ts"
import { findChecks } from "../support/hidden.ts"
import { MASTER, runKoans } from "./child.ts"

const FIX = "Fix the bug in {review} in place. The hidden checks name what still fails."
const VERIFY = { KOANS_VERIFY: "1" }

const paths = (fixture: string, stem = "01_cart"): { dir: string; koan: string; review: string } => {
  const dir = `verify/fixtures/${fixture}`
  return { dir, koan: `${dir}/${stem}_test.ts`, review: `${dir}/review/${stem}.ts` }
}

function footer(fixture: string, message: string, stem = "01_cart"): string {
  const { koan, review } = paths(fixture, stem)
  return [
    message,
    MASTER,
    `Write:        ${review}`,
    `Exercised by: ${koan}:5`,
    `    ${FIX.replace("{review}", review)}`,
  ].join("\n")
}

const koansLines = (output: string): string[] => output.split("\n").filter((line) => line.startsWith("KOANS-"))

function kindLines(fixture: string, kind: string): string[] {
  const { koan } = paths(fixture)
  return [`KOANS-TEST ${kind} ${koan}:4`, `KOANS-RESULT ${kind} ${koan}:5`]
}

function run(fixture: string): { code: number; output: string } {
  return runKoans(paths(fixture).dir, [], VERIFY)
}

afterEach(() => {
  vi.useRealTimers()
})

test("an exploit failure shows the label only", () => {
  const done = run("hidden_exploit")
  expect(done.code).toBe(1)
  expect(done.output).toContain(`\n${footer("hidden_exploit", "A hidden case still fails: an empty add")}\n0 of 1 koans answered.\n`)
  expect(done.output).not.toContain("ZX-99")
  expect(done.output).not.toContain("assert")
  expect(done.output).not.toContain("expected")
  expect(koansLines(done.output)).toEqual(kindLines("hidden_exploit", "HiddenCase:exploit"))
})

test("a twin failure is reported as twin", () => {
  const done = run("hidden_twin")
  expect(done.output).toContain(footer("hidden_twin", "A hidden case still fails: adding an item"))
  expect(done.output).not.toContain("PEAR-7")
  expect(koansLines(done.output)).toEqual(kindLines("hidden_twin", "HiddenCase:twin"))
})

test("a throw in the learner's code names the error only", () => {
  const done = run("hidden_raised")
  const message = "A hidden case still fails: an unknown item (it raised RangeError)"
  expect(done.output).toContain(footer("hidden_raised", message))
  expect(done.output).not.toContain("GHOST-1")
  expect(koansLines(done.output)).toEqual(kindLines("hidden_raised", "HiddenCase:exploit"))
})

test("a promise that never settles fails its case and the run ends", () => {
  const started = process.hrtime.bigint()
  const done = run("hidden_never_settles")
  const seconds = Number(process.hrtime.bigint() - started) / 1e9
  expect(seconds).toBeLessThan(25)
  const message = "A hidden case still fails: a reservation that never finishes"
  expect(done.output).toContain(footer("hidden_never_settles", message))
  expect(done.output).not.toContain("Timeout")
  expect(koansLines(done.output)).toEqual(kindLines("hidden_never_settles", "HiddenCase:exploit"))
})

test("an unhandled rejection fails the case under its label and is not dumped", () => {
  const fixture = "hidden_unhandled_rejection"
  const done = run(fixture)
  expect(done.code).toBe(1)
  const message = "A hidden case still fails: a warehouse that is down (it left a rejection unhandled)"
  expect(done.output).toContain(`\n${footer(fixture, message)}\n0 of 2 koans answered.\n`)
  for (const leaked of ["Unhandled", "Errors", "WAREHOUSE-DOWN-7", "NOTE-REFUSED-3"]) {
    expect(done.output).not.toContain(leaked)
  }
  const note = paths(fixture, "02_note").koan
  expect(koansLines(done.output)).toEqual([
    `KOANS-TEST HiddenCase:exploit ${paths(fixture).koan}:4`,
    `KOANS-TEST HiddenCase:exploit ${note}:4`,
    `KOANS-RESULT HiddenCase:exploit ${paths(fixture).koan}:5`,
  ])
  const alone = runKoans(paths(fixture).dir, [note], VERIFY)
  expect(alone.output).toContain(footer(fixture, "A hidden case still fails: a refused note (it left a rejection unhandled)", "02_note"))
})

test("a review that does not load names the file to fix", () => {
  const done = run("hidden_syntax")
  const { koan, review } = paths("hidden_syntax")
  expect(done.output).toMatch(new RegExp(`\\n${review} does not load: \\S`))
  expect(done.output).toContain(`\n${MASTER}\nWrite:        ${review}\nExercised by: ${koan}:5\n`)
  expect(koansLines(done.output)).toEqual(kindLines("hidden_syntax", "ReviewDidNotLoad"))
})

test("a review's top-level code runs under the guard", () => {
  const done = run("hidden_guarded")
  const { review } = paths("hidden_guarded")
  expect(done.output).toContain(footer("hidden_guarded", `${review} does not load: koans start no processes`))
  expect(koansLines(done.output)).toEqual(kindLines("hidden_guarded", "ReviewDidNotLoad"))
})

test("each case gets a fresh module", () => {
  const done = run("hidden_fresh_state")
  expect(done.code).toBe(0)
  expect(koansLines(done.output)).toEqual([`KOANS-TEST ok ${paths("hidden_fresh_state").koan}:4`, "KOANS-RESULT ok"])
})

test("each case gets fresh sibling modules too", () => {
  const done = run("hidden_fresh_sibling")
  expect(done.code).toBe(0)
  expect(koansLines(done.output)).toEqual([`KOANS-TEST ok ${paths("hidden_fresh_sibling").koan}:4`, "KOANS-RESULT ok"])
})

test("a rejection in the review's top-level code is labelled, not dumped", () => {
  const fixture = "hidden_load_rejection"
  const done = run(fixture)
  expect(done.output.startsWith(`\n${footer(fixture, "A hidden case still fails: adding an item (it left a rejection unhandled)")}\n`)).toBe(true)
  expect(done.output).not.toContain("TOPLEVEL-SECRET-1")
  expect(koansLines(done.output)).toEqual(kindLines(fixture, "HiddenCase:twin"))
})

test("a review that never finishes loading names the file to fix", () => {
  const started = process.hrtime.bigint()
  const done = run("hidden_never_loads")
  const seconds = Number(process.hrtime.bigint() - started) / 1e9
  expect(seconds).toBeLessThan(25)
  const { review } = paths("hidden_never_loads")
  expect(done.output).toContain(footer("hidden_never_loads", `${review} does not load: it never finished loading`))
  expect(koansLines(done.output)).toEqual(kindLines("hidden_never_loads", "ReviewDidNotLoad"))
})

test("a timer left by one case never fires in the next", () => {
  const done = run("hidden_leftover_interval")
  expect(done.code).toBe(0)
  expect(koansLines(done.output)).toEqual([`KOANS-TEST ok ${paths("hidden_leftover_interval").koan}:4`, "KOANS-RESULT ok"])
})

test("checks are found from a nested variant folder", () => {
  const done = run("hidden_nested")
  expect(done.code).toBe(0)
  expect(koansLines(done.output)).toEqual([`KOANS-TEST ok ${paths("hidden_nested/stage/v0001").koan}:4`, "KOANS-RESULT ok"])
})

test("each case starts in the course zone", () => {
  const done = run("hidden_zone")
  expect(done.code).toBe(0)
  expect(koansLines(done.output)).toEqual([`KOANS-TEST ok ${paths("hidden_zone").koan}:4`, "KOANS-RESULT ok"])
})

test("a claimed rejection is filtered from the run's unhandled errors", async () => {
  vi.resetModules()
  const filter = (await import("../vitest.config.ts")).default.test?.onUnhandledError
  const claimed = Object.assign(new Error("claimed"), { koansClaimed: true, type: "Unhandled Rejection" })
  const stray = Object.assign(new Error("stray"), { type: "Unhandled Rejection" })
  expect(filter?.(claimed)).toBe(false)
  expect(filter?.(stray)).toBe(true)
})

test("the checks search stops at the track root", () => {
  const root = realpathSync(mkdtempSync(join(tmpdir(), "koans-checks-")))
  const track = join(root, "track")
  mkdirSync(join(root, "checks"))
  writeFileSync(join(root, "checks", "01_cart_checks.ts"), "export const CASES = []\n")
  mkdirSync(join(track, "koans"), { recursive: true })
  writeFileSync(join(track, "package.json"), "{}\n")
  const koan = join(track, "koans", "01_cart_test.ts")
  expect(() => findChecks(koan, "01_cart")).toThrow(/01_cart_checks\.ts/)
  mkdirSync(join(track, "checks"))
  writeFileSync(join(track, "checks", "01_cart_checks.ts"), "export const CASES = []\n")
  expect(findChecks(koan, "01_cart")).toBe(join(track, "checks", "01_cart_checks.ts"))
})

test("settle reports done, error and not-done", async () => {
  const failure = new RangeError("no")
  expect(await settle(Promise.resolve(7))).toEqual({ done: true, value: 7 })
  expect(await settle(Promise.reject(failure))).toEqual({ done: true, error: failure })
  expect(await settle(new Promise(() => {}), 3)).toEqual({ done: false })
  vi.useFakeTimers({ toFake: ["setTimeout", "setInterval", "setImmediate"] })
  const timed = new Promise((resolve) => setTimeout(() => resolve("late"), 60_000))
  expect(await settle(timed)).toEqual({ done: true, value: "late" })
  let ticks = 0
  setInterval(() => {
    ticks += 1
  }, 10)
  expect(await settle(new Promise(() => {}), 5)).toEqual({ done: false })
  expect(ticks).toBeLessThanOrEqual(5)
  expect(ticks).toBeGreaterThan(0)
})

async function refusal(run: () => unknown): Promise<unknown> {
  try {
    await run()
  } catch (error) {
    return error
  }
  return null
}

function expectBareAssertion(error: unknown): void {
  expect(error).toBeInstanceOf(AssertionError)
  expect((error as Error).message).toBe("")
}

test("rejects and throws accept the named type and refuse others", async () => {
  throws(() => {
    throw new RangeError("accepted")
  }, TypeError, RangeError)
  await rejects(Promise.reject(new TypeError("accepted")), TypeError)
  expectBareAssertion(await refusal(() => throws(() => 1, RangeError)))
  expectBareAssertion(
    await refusal(() =>
      throws(() => {
        throw new TypeError("refused")
      }, RangeError),
    ),
  )
  expectBareAssertion(await refusal(() => rejects(Promise.resolve(1), RangeError)))
  expectBareAssertion(await refusal(() => rejects(Promise.reject(new TypeError("refused")), RangeError)))
  expectBareAssertion(await refusal(() => rejects(new Promise(() => {}), RangeError)))
})
