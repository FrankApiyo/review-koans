import * as cp from "node:child_process"
import { exec } from "node:child_process"
import { execFile as runFile } from "node:child_process"
import { Worker } from "node:worker_threads"
import { test } from "vitest"
import { WRITE, marker } from "./marker.ts"

test("Spawn through a namespace import is refused.", () => {
  cp.spawn("sh", ["-c", WRITE, "sh", marker("spawn")])
})

test("A named exec is refused.", () => {
  exec(`sh -c '${WRITE}' sh "${marker("exec")}"`)
})

test("An aliased execFile is refused.", () => {
  runFile("sh", ["-c", WRITE, "sh", marker("execFile")])
})

test("A dynamically imported fork is refused.", async () => {
  const imported = await import("node:child_process")
  imported.fork(new URL("./mark.mjs", import.meta.url), [marker("fork")])
})

test("A worker thread is refused.", () => {
  const code = `require("node:fs").writeFileSync(${JSON.stringify(marker("worker"))}, "ran")`
  new Worker(code, { eval: true })
})

test("A ChildProcess spawned by hand is refused.", () => {
  const file = "sh"
  new cp.ChildProcess().spawn({ file, args: [file, "-c", WRITE, file, marker("ChildProcess")], stdio: "ignore" })
})
