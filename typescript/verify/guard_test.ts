import { spawnSync } from "node:child_process"
import * as childProcess from "node:child_process"
import { mkdtempSync, readdirSync, readFileSync, realpathSync, rmSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { expect, test } from "vitest"
import { armGuard, disarmGuard, installGuard } from "../support/guard.ts"
import { MASTER, runKoans } from "./child.ts"
import { type Koan, koanAt, koansIn, koansLines } from "./koans.ts"

const OFFLINE_DIR = "verify/fixtures/offline"
const OFFLINE = `${OFFLINE_DIR}/01_offline_test.ts`
const PROCESSES_DIR = "verify/fixtures/processes"
const SPAWNS = `${PROCESSES_DIR}/01_spawn_test.ts`
const SYNC = `${PROCESSES_DIR}/02_sync_test.ts`
const NATIVE = `${PROCESSES_DIR}/03_native_test.ts`
const AFTER = `${PROCESSES_DIR}/04_after_test.ts`
const OFFLINE_MESSAGE = "Error: koans are offline"
const PROCESS_MESSAGE = "Error: koans start no processes"

function withMarkers<T>(run: (dir: string) => T): T {
  const dir = realpathSync(mkdtempSync(join(tmpdir(), "koans-markers-")))
  try {
    return run(dir)
  } finally {
    rmSync(dir, { recursive: true, force: true })
  }
}

function expectRefused(dir: string, file: string, koan: Koan, message: string, env: Record<string, string> = {}): void {
  const done = runKoans(dir, [`${file}:${koan.line}`], { ...env, KOANS_VERIFY: "1" })
  expect(koansLines(done.output)[0], koan.meditation).toBe(`KOANS-TEST Error ${file}:${koan.line}`)
  expect(done.output, koan.meditation).toContain(`${message}\n${MASTER}\nMeditate on ${file}:`)
  expect(done.output, koan.meditation).toContain(`\n    ${koan.meditation}\n`)
}

function expectAllRefused(dir: string, file: string, message: string, env: Record<string, string> = {}): void {
  const koans = koansIn(file)
  expect(koans.length).toBeGreaterThan(0)
  for (const koan of koans) expectRefused(dir, file, koan, message, env)
}

test("a TCP connect is refused", () => {
  for (const meditation of ["A TCP connect is refused.", "A named createConnection is refused."]) {
    expectRefused(OFFLINE_DIR, OFFLINE, koanAt(OFFLINE, meditation), OFFLINE_MESSAGE)
  }
})

test("fetch is refused", () => {
  expectRefused(OFFLINE_DIR, OFFLINE, koanAt(OFFLINE, "Fetch is refused."), OFFLINE_MESSAGE)
})

test("a DNS lookup is refused", () => {
  for (const meditation of [
    "A DNS lookup is refused.",
    "A promised DNS lookup is refused.",
    "A DNS query on a resolver is refused.",
  ]) {
    expectRefused(OFFLINE_DIR, OFFLINE, koanAt(OFFLINE, meditation), OFFLINE_MESSAGE)
  }
})

test("every network path is refused, however net is imported", () => {
  expectAllRefused(OFFLINE_DIR, OFFLINE, OFFLINE_MESSAGE)
})

test("spawn, exec, execFile and fork are refused", () => {
  withMarkers((dir) => expectAllRefused(PROCESSES_DIR, SPAWNS, PROCESS_MESSAGE, { KOANS_MARKER_DIR: dir }))
})

test("spawnSync, execSync and execFileSync are refused, named and namespace imports alike", () => {
  withMarkers((dir) => expectAllRefused(PROCESSES_DIR, SYNC, PROCESS_MESSAGE, { KOANS_MARKER_DIR: dir }))
})

test("raw bindings, native addons and execve are refused", () => {
  withMarkers((dir) => expectAllRefused(PROCESSES_DIR, NATIVE, PROCESS_MESSAGE, { KOANS_MARKER_DIR: dir }))
})

test("the child process really did not run", () => {
  withMarkers((dir) => {
    const done = runKoans(PROCESSES_DIR, [SPAWNS, SYNC], { KOANS_VERIFY: "1", KOANS_MARKER_DIR: dir })
    const kinds = koansLines(done.output).filter((line) => line.startsWith("KOANS-TEST"))
    expect(kinds).toHaveLength(koansIn(SPAWNS).length + koansIn(SYNC).length)
    expect(kinds.every((line) => line.startsWith("KOANS-TEST Error "))).toBe(true)
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 500)
    expect(readdirSync(dir)).toEqual([])
  })
})

test("the guard is off outside a koan, even after a koan throws", () => {
  withMarkers((dir) => {
    const done = runKoans(PROCESSES_DIR, [AFTER], { KOANS_VERIFY: "1", KOANS_MARKER_DIR: dir })
    expect(koansLines(done.output)[0]).toBe(`KOANS-TEST Error ${AFTER}:${koanAt(AFTER, "A koan that throws the refusal.").line}`)
    expect(done.output).toContain(PROCESS_MESSAGE)
    expect(readFileSync(join(dir, "after-all"), "utf8")).toBe("0")
  })
})

test("installGuard is idempotent and refuses only while armed", () => {
  installGuard()
  const guarded = childProcess.spawnSync
  installGuard()
  expect(childProcess.spawnSync).toBe(guarded)
  expect(spawnSync("true").status).toBe(0)
  armGuard()
  try {
    expect(() => spawnSync("true")).toThrow(new Error("koans start no processes"))
    expect(() => fetch("http://127.0.0.1:9/")).toThrow(new Error("koans are offline"))
  } finally {
    disarmGuard()
  }
  expect(spawnSync("true").status).toBe(0)
})
