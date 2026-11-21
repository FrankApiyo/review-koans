import { createRequire } from "node:module"
import * as nodeModule from "node:module"
import { register } from "node:module"
import { register as hook } from "node:module"
import { test } from "vitest"
import { WRITE, marker } from "./marker.ts"

function hooks(name: string): string {
  const spawn = `import("node:child_process").then((cp) => cp.spawnSync("sh", ["-c", ${JSON.stringify(WRITE)}, "sh", ${JSON.stringify(marker(name))}]))`
  return `data:text/javascript,${encodeURIComponent(spawn)}`
}

test("register through a namespace import is refused.", () => {
  nodeModule.register(hooks("register-namespace"))
})

test("A named register is refused.", () => {
  register(hooks("register-named"))
})

test("An aliased register is refused.", () => {
  hook(hooks("register-alias"))
})

test("A required register is refused.", () => {
  const required: typeof nodeModule = createRequire(import.meta.url)("node:module")
  required.register(hooks("register-required"))
})

test("A dynamically imported register is refused.", async () => {
  const imported = await import("node:module")
  imported.register(hooks("register-dynamic"))
})
