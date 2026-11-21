import { spawnSync } from "node:child_process"
import * as childProcess from "node:child_process"
import { expect, test } from "vitest"
import { installGuard } from "../support/guard.ts"

test("installGuard is idempotent and refuses from then on", () => {
  expect(spawnSync("true").status).toBe(0)
  installGuard()
  const guarded = childProcess.spawnSync
  installGuard()
  expect(childProcess.spawnSync).toBe(guarded)
  expect(() => spawnSync("true")).toThrow(new Error("koans start no processes"))
  expect(() => fetch("http://127.0.0.1:9/")).toThrow(new Error("koans are offline"))
})
