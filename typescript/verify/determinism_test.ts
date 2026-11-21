import { expect, test } from "vitest"
import { runKoans } from "./child.ts"
import { koanAt, koansIn, koansLines } from "./koans.ts"

const TIMERS_DIR = "verify/fixtures/timers"
const TIMERS = `${TIMERS_DIR}/01_timers_test.ts`
const ZONES_DIR = "verify/fixtures/zones"
const ZONES = `${ZONES_DIR}/01_zones_test.ts`
const VERIFY = { KOANS_VERIFY: "1" }
const MACHINES: Record<string, string>[] = [
  { TZ: "Pacific/Auckland", LANG: "de_DE.UTF-8", LC_ALL: "de_DE.UTF-8" },
  { TZ: "Asia/Kolkata", LANG: "ja_JP.UTF-8", LC_ALL: "ja_JP.UTF-8" },
  { TZ: "UTC", LANG: "C", LC_ALL: "C" },
]

function expectKoanPasses(file: string, dir: string, meditation: string): void {
  const { line } = koanAt(file, meditation)
  const done = runKoans(dir, [`${file}:${line}`], VERIFY)
  expect(koansLines(done.output), done.output).toEqual([`KOANS-TEST ok ${file}:${line}`, "KOANS-RESULT ok"])
}

function allPass(file: string): string[] {
  return [...koansIn(file).map(({ line }) => `KOANS-TEST ok ${file}:${line}`), "KOANS-RESULT ok"]
}

test("every koan runs under fake timers", () => {
  expectKoanPasses(TIMERS, TIMERS_DIR, "A long timeout runs after drain.")
})

test("later resolves after microtasks queued before it", () => {
  expectKoanPasses(TIMERS, TIMERS_DIR, "Later resolves after microtasks queued before it.")
})

test("drain stops after its turns on a setInterval", () => {
  expectKoanPasses(TIMERS, TIMERS_DIR, "Drain stops after its turns on a setInterval.")
})

test("a setTimeout imported from node:timers", () => {
  expectKoanPasses(TIMERS, TIMERS_DIR, "A setTimeout imported from node:timers runs after drain.")
  expectKoanPasses(TIMERS, TIMERS_DIR, "A promised timeout from node:timers/promises resolves after drain.")
})

test("fake timers do not leak between koans", () => {
  const done = runKoans(TIMERS_DIR, [], VERIFY)
  expect(koansLines(done.output), done.output).toEqual(allPass(TIMERS))
})

test("TZ is America/New_York inside a koan and restored after inZone", () => {
  const done = runKoans(ZONES_DIR, [], VERIFY)
  expect(koansLines(done.output), done.output).toEqual(allPass(ZONES))
})

test("solutions pass under another machine zone and locale", () => {
  for (const machine of MACHINES) {
    const done = runKoans(ZONES_DIR, [], { ...VERIFY, ...machine })
    expect(koansLines(done.output), machine.TZ).toEqual(allPass(ZONES))
  }
})
