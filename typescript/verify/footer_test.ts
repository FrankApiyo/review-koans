import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { expect, test } from "vitest"
import { render, separator, total } from "../support/footer.ts"
import { ENLIGHTENMENT, MASTER } from "./child.ts"

test("the separator is 80 columns, centred", () => {
  expect(separator("The master says")).toBe(MASTER)
  expect(separator("Enlightenment")).toBe(ENLIGHTENMENT)
  expect(MASTER.length).toBe(80)
  expect(ENLIGHTENMENT.length).toBe(80)
})

test("a value blank footer", () => {
  const failure = {
    path: "koans/01_equality_test.ts",
    line: 7,
    meditation: "What does the second call return?",
    message: "Replace __ with the value that makes this true.",
    write: null,
  }
  expect(render(1, 3, 2, failure)).toBe(
    "Replace __ with the value that makes this true.\n" +
      `${MASTER}\n` +
      "Meditate on koans/01_equality_test.ts:7\n" +
      "    What does the second call return?\n" +
      "1 of 3 koans answered.",
  )
})

test("a verdict footer keeps both message lines", () => {
  const failure = {
    path: "koans/00_about_koans_test.ts",
    line: 12,
    meditation: 'Read koans/review/00_discount.ts. Write "fine", or the line number of the bug.',
    message:
      "Not that line. Look again at koans/review/00_discount.ts.\n" +
      "koans/review/00_discount.ts has changed since it was generated, so its line numbers may have moved: " +
      "git diff koans/review/00_discount.ts shows how.",
    write: null,
  }
  expect(render(0, 4, 1, failure)).toBe(
    "Not that line. Look again at koans/review/00_discount.ts.\n" +
      "koans/review/00_discount.ts has changed since it was generated, so its line numbers may have moved: " +
      "git diff koans/review/00_discount.ts shows how.\n" +
      `${MASTER}\n` +
      "Meditate on koans/00_about_koans_test.ts:12\n" +
      '    Read koans/review/00_discount.ts. Write "fine", or the line number of the bug.\n' +
      "0 of 4 koans answered.",
  )
})

test("a hidden case footer names the file to write", () => {
  const failure = {
    path: "koans/02_references_test.ts",
    line: 20,
    meditation: "Fix the bug in koans/review/02_make_config.ts in place. The hidden checks name what still fails.",
    message: "A hidden case still fails: two configs share one list (it raised TypeError)",
    write: "koans/review/02_make_config.ts",
  }
  expect(render(2, 5, 3, failure)).toBe(
    "A hidden case still fails: two configs share one list (it raised TypeError)\n" +
      `${MASTER}\n` +
      "Write:        koans/review/02_make_config.ts\n" +
      "Exercised by: koans/02_references_test.ts:20\n" +
      "    Fix the bug in koans/review/02_make_config.ts in place. The hidden checks name what still fails.\n" +
      "2 of 5 koans answered.",
  )
})

test("a koan file that does not load has no line and no meditation", () => {
  const failure = {
    path: "koans/01_equality_test.ts",
    line: null,
    meditation: null,
    message: "koans/01_equality_test.ts does not load: Unexpected token",
    write: null,
  }
  expect(render(0, 3, 0, failure)).toBe(
    "koans/01_equality_test.ts does not load: Unexpected token\n" +
      `${MASTER}\n` +
      "Meditate on koans/01_equality_test.ts\n" +
      "0 of 3 koans answered.",
  )
})

test("the enlightenment footer", () => {
  expect(render(3, 3, 3, null)).toBe(`${ENLIGHTENMENT}\nAll 3 koans pass. Start again with: git checkout -- koans/`)
})

test("the partial footer", () => {
  expect(render(1, 3, 1, null)).toBe("1 of 3 koans answered. Run the whole suite for the rest.")
})

test("a run with no koan prints no footer", () => {
  expect(render(0, 3, 0, null)).toBe("")
})

test("total counts test( heads in numbered koan files only", () => {
  const folder = mkdtempSync(join(tmpdir(), "koans-total-"))
  try {
    writeFileSync(join(folder, "01_a_test.ts"), 'test("a", () => {})\n\ntest("b", () => {})\n')
    writeFileSync(join(folder, "02_b_test.ts"), 'test("c", () => {\n  const s = \'test("not at line start")\'\n})\n')
    writeFileSync(join(folder, "helper_test.ts"), 'test("d", () => {})\n')
    mkdirSync(join(folder, "review"))
    writeFileSync(join(folder, "review", "03_c_test.ts"), 'test("e", () => {})\n')
    expect(total(folder)).toBe(3)
  } finally {
    rmSync(folder, { recursive: true, force: true })
  }
})
