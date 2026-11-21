import { createRequire } from "node:module"
import * as cp from "node:child_process"
import { execFileSync, execSync, spawnSync } from "node:child_process"
import { spawnSync as run } from "node:child_process"
import { test } from "vitest"
import { WRITE, marker } from "./marker.ts"

const captured = cp.execSync

test("spawnSync through a namespace import is refused.", () => {
  cp.spawnSync("sh", ["-c", WRITE, "sh", marker("spawnSync-namespace")])
})

test("A named spawnSync is refused.", () => {
  spawnSync("sh", ["-c", WRITE, "sh", marker("spawnSync-named")])
})

test("An aliased spawnSync is refused.", () => {
  run("sh", ["-c", WRITE, "sh", marker("spawnSync-alias")])
})

test("A dynamically imported spawnSync is refused.", async () => {
  const imported = await import("node:child_process")
  imported.spawnSync("sh", ["-c", WRITE, "sh", marker("spawnSync-dynamic")])
})

test("A required spawnSync is refused.", () => {
  const required: typeof cp = createRequire(import.meta.url)("node:child_process")
  required.spawnSync("sh", ["-c", WRITE, "sh", marker("spawnSync-required")])
})

test("execSync is refused.", () => {
  execSync(`sh -c '${WRITE}' sh "${marker("execSync")}"`)
})

test("execFileSync is refused.", () => {
  execFileSync("sh", ["-c", WRITE, "sh", marker("execFileSync")])
})

test("An execSync captured before the koan is refused.", () => {
  captured(`sh -c '${WRITE}' sh "${marker("execSync-captured")}"`)
})
