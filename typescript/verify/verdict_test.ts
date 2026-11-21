import { createHash } from "node:crypto"
import { mkdirSync, mkdtempSync, realpathSync, rmSync, writeFileSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { afterAll, afterEach, beforeAll, beforeEach, expect, test } from "vitest"
import { Blank, __ } from "../support/blank.ts"
import { Verdict, digest, reviewPath, verdict } from "../support/verdict.ts"

const CART = "export function total(items: number[]): number {\n  let result = 0\n  for (const item of items) {\n    result = item\n  }\n  return result\n}\n"
const PATH = "koans/review/cart.ts"
const BUGGY = [4, 3].map((line) => digest("cart.ts", line)).join(",")
const FINE = digest("cart.ts", "fine")

const sha = (text: string): string => createHash("sha256").update(text, "utf8").digest("hex").slice(0, 10)

let root = ""
let home = ""
let testPath: string | undefined

beforeAll(() => {
  root = realpathSync(mkdtempSync(join(tmpdir(), "koans-verdict-")))
  mkdirSync(join(root, "koans", "review"), { recursive: true })
})

afterAll(() => {
  rmSync(root, { recursive: true, force: true })
})

beforeEach(() => {
  writeFileSync(join(root, PATH), CART)
  home = process.cwd()
  process.chdir(root)
  testPath = expect.getState().testPath
  expect.setState({ testPath: join(root, "koans", "01_cart_test.ts") })
})

afterEach(() => {
  expect.setState({ testPath })
  process.chdir(home)
})

function refusal(answer: unknown, digests: string, sourceDigest = sha(CART)): string {
  try {
    verdict("cart.ts", answer, digests, sourceDigest)
  } catch (error) {
    expect(error).toBeInstanceOf(Verdict)
    expect((error as Verdict).name).toBe("Verdict")
    expect((error as Verdict).reviewPath).toBe(PATH)
    return (error as Verdict).message
  }
  throw new Error("expected the verdict to be refused")
}

test("digest matches the generator vectors", () => {
  expect(digest("cart.ex", 14)).toBe("d5882bb7c9")
  expect(digest("cart.ex", "fine")).toBe("dc2c050639")
})

test("the review path is the koan folder relative to cwd", () => {
  expect(reviewPath(join(root, "koans", "01_cart_test.ts"), "cart.ts")).toBe(PATH)
})

test("accepts a line in the set", () => {
  expect(verdict("cart.ts", 4, BUGGY, sha(CART))).toBeUndefined()
  expect(verdict("cart.ts", 3, BUGGY, sha(CART))).toBeUndefined()
})

test("accepts fine for a fine file", () => {
  expect(verdict("cart.ts", "fine", FINE, sha(CART))).toBeUndefined()
})

test("says has a bug when fine on a buggy file", () => {
  expect(refusal("fine", BUGGY)).toBe(`Not fine: ${PATH} has a bug. Write the number of the line where it is.`)
})

test("says it is fine when a line on a fine file", () => {
  expect(refusal(4, FINE)).toBe(`Read ${PATH} again: it is fine. Write "fine".`)
})

test("says not that line", () => {
  expect(refusal(2, BUGGY)).toBe(`Not that line. Look again at ${PATH}.`)
})

test("a wrong line on an edited review adds the moved-lines note", () => {
  writeFileSync(join(root, PATH), `\n${CART}`)
  expect(refusal(2, BUGGY)).toBe(
    `Not that line. Look again at ${PATH}.\n` +
      `${PATH} has changed since it was generated, so its line numbers may have moved: git diff ${PATH} shows how.`,
  )
})

test("a missing review counts as changed", () => {
  rmSync(join(root, PATH))
  expect(refusal(2, BUGGY)).toMatch(/git diff koans\/review\/cart\.ts shows how\.$/)
})

test("refuses other strings, 0, a negative, 2.5, NaN and true as bad shape", () => {
  for (const answer of ["4", "Fine", 0, -4, 2.5, NaN, true, null, 2 ** 53]) {
    expect(refusal(answer, BUGGY)).toBe(`Write "fine", or a line number of ${PATH} as an integer.`)
  }
})

test("a verdict blank names the review path", () => {
  try {
    verdict("cart.ts", __, BUGGY, sha(CART))
  } catch (error) {
    expect(error).toBeInstanceOf(Blank)
    expect((error as Blank).kind).toBe("verdict")
    expect((error as Blank).reviewPath).toBe(PATH)
    expect((error as Blank).message).toBe(`Replace __ with "fine", or the number of the line with the bug in ${PATH}.`)
    return
  }
  throw new Error("expected a blank")
})
