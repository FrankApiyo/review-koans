import { readFile } from "node:fs/promises"
import { writeFileSync } from "node:fs"
import { afterAll, expect, test } from "vitest"
import { attempt, marker } from "./marker.ts"

const late: { outcome?: Promise<string> } = {}

afterAll(async () => {
  writeFileSync(marker("late"), await (late.outcome ?? Promise.resolve("never scheduled")))
})

test("A koan that leaves an I/O callback behind.", () => {
  late.outcome = readFile(new URL(import.meta.url)).then(() => attempt())
  expect(late.outcome).toBeInstanceOf(Promise)
})
