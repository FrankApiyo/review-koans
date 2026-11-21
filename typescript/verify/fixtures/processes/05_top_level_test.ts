import { spawnSync } from "node:child_process"
import { expect, test } from "vitest"
import { WRITE, marker } from "./marker.ts"

spawnSync("sh", ["-c", WRITE, "sh", marker("top-level")])

test("A koan after a top-level spawn.", () => {
  expect(1).toEqual(1)
})
