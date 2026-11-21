import { spawnSync } from "node:child_process"
import { writeFileSync } from "node:fs"
import { afterAll, test } from "vitest"
import { attempt, marker } from "./marker.ts"

afterAll(() => {
  writeFileSync(marker("after-all"), attempt())
})

test("A koan that throws the refusal.", () => {
  spawnSync("true")
})
