import { cpSync, readFileSync, rmSync } from "node:fs"
import { join } from "node:path"
import { expect, test, vi } from "vitest"
import { ENLIGHTENMENT, MASTER, TYPESCRIPT_DIR, runKoans } from "./child.ts"

const TWO_FILES = "verify/fixtures/two_files"
const FIRST = `${TWO_FILES}/01_first_test.ts`
const SECOND = `${TWO_FILES}/02_second_test.ts`
const SINGLE = "verify/fixtures/single_file"
const ALPHA = `${SINGLE}/01_alpha_test.ts`
const VERDICTS = "verify/fixtures/verdicts"
const KOAN = `${VERDICTS}/01_verdicts_test.ts`
const SOLVED = "verify/fixtures/solved"
const BROKEN_DIR = "verify/fixtures/koan_syntax_error"
const BROKEN = `${BROKEN_DIR}/01_broken_test.ts`
const VALUE = "Replace __ with the value that makes this true."
const VERIFY = { KOANS_VERIFY: "1" }
const NO_MATCH = "No koan file matches. Check the path and the file name, for example: npx vitest run koans/01_equality_test.ts"

async function learnerBail(verify: string | undefined): Promise<unknown> {
  vi.resetModules()
  vi.stubEnv("KOANS_VERIFY", verify)
  try {
    return (await import("../vitest.config.ts")).default.test?.bail
  } finally {
    vi.unstubAllEnvs()
  }
}

const koansLines = (output: string): string[] => output.split("\n").filter((line) => line.startsWith("KOANS-"))

test("two failing files name the earlier one", () => {
  const footer = `${VALUE}\n${MASTER}\nMeditate on ${FIRST}:9\n    What is two?\n1 of 3 koans answered.`
  const plain = runKoans(TWO_FILES)
  expect(plain.code).toBe(1)
  expect(plain.output).toContain(footer)
  const reversed = runKoans(TWO_FILES, [SECOND, FIRST], VERIFY)
  expect(koansLines(reversed.output)).toEqual([
    `KOANS-TEST ok ${FIRST}:4`,
    `KOANS-TEST Blank ${FIRST}:8`,
    `KOANS-TEST Blank ${SECOND}:4`,
    `KOANS-RESULT Blank ${FIRST}:9`,
  ])
  expect(reversed.output).toContain(footer)
})

test("stops at the first failing koan", async () => {
  expect(await learnerBail(undefined)).toBe(1)
  expect(await learnerBail("1")).toBe(0)
  const done = runKoans(VERDICTS)
  expect(done.code).toBe(1)
  expect(done.output.trim()).toBe(
    'Read verify/fixtures/verdicts/review/fine.ts again: it is fine. Write "fine".\n' +
      `${MASTER}\n` +
      `Meditate on ${KOAN}:9\n` +
      '    Read verify/fixtures/verdicts/review/fine.ts. Write "fine", or the line number of the bug.\n' +
      "1 of 4 koans answered.",
  )
  const ran = runKoans(VERDICTS, ["--bail=1"], VERIFY)
  expect(koansLines(ran.output)).toEqual([
    `KOANS-TEST ok ${KOAN}:4`,
    `KOANS-TEST Verdict ${KOAN}:8`,
    `KOANS-RESULT Verdict ${KOAN}:9`,
  ])
})

test("a single file prints the partial footer", () => {
  const done = runKoans(SINGLE, [ALPHA])
  expect(done.code).toBe(0)
  expect(done.output.trim()).toBe("2 of 3 koans answered. Run the whole suite for the rest.")
})

test("a line filter runs one koan", () => {
  const done = runKoans(SINGLE, [`${ALPHA}:7`], VERIFY)
  expect(done.code).toBe(0)
  expect(koansLines(done.output)).toEqual([`KOANS-TEST ok ${ALPHA}:7`, "KOANS-RESULT ok"])
  expect(done.output).toContain("\n1 of 3 koans answered. Run the whole suite for the rest.\n")
})

test("the solved fixture reaches enlightenment", () => {
  const done = runKoans(SOLVED)
  expect(done.code).toBe(0)
  expect(done.output.trim()).toBe(`${ENLIGHTENMENT}\nAll 3 koans pass. Start again with: git checkout -- koans/`)
})

test("verify mode prints a KOANS-TEST line per koan and a result", () => {
  const done = runKoans(VERDICTS, [], VERIFY)
  expect(done.code).toBe(1)
  expect(koansLines(done.output)).toEqual([
    `KOANS-TEST ok ${KOAN}:4`,
    `KOANS-TEST Verdict ${KOAN}:8`,
    `KOANS-TEST Blank ${KOAN}:12`,
    `KOANS-TEST Blank ${KOAN}:17`,
    `KOANS-RESULT Verdict ${KOAN}:9`,
  ])
})

test("a value blank fails on its own line", () => {
  const done = runKoans(VERDICTS, [`${KOAN}:12`], VERIFY)
  expect(koansLines(done.output)).toEqual([`KOANS-TEST Blank ${KOAN}:12`, `KOANS-RESULT Blank ${KOAN}:14`])
  expect(done.output).toContain(`${VALUE}\n${MASTER}\nMeditate on ${KOAN}:14\n    What is one plus one?\n`)
})

test("a koan file with a syntax error is named, not skipped", () => {
  const done = runKoans(BROKEN_DIR, [], VERIFY)
  expect(done.code).toBe(1)
  expect(koansLines(done.output)).toEqual([
    `KOANS-TEST ok ${BROKEN_DIR}/02_after_test.ts:3`,
    `KOANS-RESULT LoadError ${BROKEN}:8`,
  ])
  expect(done.output).toContain(
    `\n${BROKEN} does not load: [PARSE_ERROR] Unexpected token\n${MASTER}\nMeditate on ${BROKEN}:8\n1 of 3 koans answered.\n`,
  )
})

test("a module error beside passing koans is a failure, not enlightenment", () => {
  const file = "verify/fixtures/module_error/01_after_all_test.ts"
  const done = runKoans("verify/fixtures/module_error", [], VERIFY)
  expect(done.code).toBe(1)
  expect(done.output).not.toContain(ENLIGHTENMENT)
  expect(done.output).toContain(`\nRangeError: cleanup failed\n${MASTER}\nMeditate on ${file}:4\n1 of 1 koans answered.\n`)
  expect(koansLines(done.output)).toEqual([`KOANS-TEST ok ${file}:7`, `KOANS-RESULT RangeError ${file}:4`])
})

test("an unhandled error is a failure, not enlightenment", () => {
  const file = "verify/fixtures/unhandled_error/01_stray_test.ts"
  const done = runKoans("verify/fixtures/unhandled_error", [], VERIFY)
  expect(done.code).toBe(1)
  expect(done.output).not.toContain(ENLIGHTENMENT)
  expect(done.output.split("\n").filter((line) => line === "TypeError: stray")).toHaveLength(1)
  expect(done.output).toContain(`\nTypeError: stray\n${MASTER}\nMeditate on ${file}:4\n1 of 1 koans answered.\n`)
  expect(koansLines(done.output)).toEqual([`KOANS-TEST ok ${file}:3`, `KOANS-RESULT TypeError ${file}:4`])
})

test("a filter that matches no koan file says so", () => {
  const done = runKoans(SINGLE, [`${SINGLE}/09_typo_test.ts`])
  expect(done.code).toBe(1)
  expect(done.output.trim()).toBe(NO_MATCH)
})

test("#koans resolves from a nested variant folder", () => {
  const variant = "_variants/verify-nested/v0001"
  const staged = join(TYPESCRIPT_DIR, variant)
  cpSync(join(TYPESCRIPT_DIR, SOLVED), staged, { recursive: true })
  try {
    expect(readFileSync(join(staged, "01_solved_test.ts"), "utf8")).toContain('from "#koans"')
    const done = runKoans(variant)
    expect(done.code).toBe(0)
    expect(done.output.trim()).toBe(`${ENLIGHTENMENT}\nAll 3 koans pass. Start again with: git checkout -- koans/`)
  } finally {
    rmSync(join(TYPESCRIPT_DIR, "_variants/verify-nested"), { recursive: true, force: true })
  }
})

test("an unhandled error with no koan frame still ends the footer without enlightenment", () => {
  const file = "verify/fixtures/unhandled_value/01_value_test.ts"
  const done = runKoans("verify/fixtures/unhandled_value", [], VERIFY)
  expect(done.code).toBe(1)
  expect(done.output).not.toContain(ENLIGHTENMENT)
  expect(done.output).toContain("\nError: stray value\n1 of 1 koans answered.\n")
  expect(koansLines(done.output)).toEqual([`KOANS-TEST ok ${file}:3`, "KOANS-RESULT Error"])
})
