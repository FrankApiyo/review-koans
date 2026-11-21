import { spawnSync } from "node:child_process"
import { writeFileSync } from "node:fs"
import { afterAll, test } from "vitest"
import { marker } from "./marker.ts"

afterAll(() => {
  writeFileSync(marker("after-all"), String(spawnSync("true").status))
})

test("A koan that throws the refusal.", () => {
  spawnSync("true")
})
