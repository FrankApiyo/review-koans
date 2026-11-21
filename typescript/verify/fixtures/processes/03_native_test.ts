import { test } from "vitest"
import { marker } from "./marker.ts"

type Native = {
  binding(name: string): unknown
  execve(file: string, args: string[]): never
}

const native = process as unknown as Native

test("A raw spawn binding is refused.", () => {
  native.binding("spawn_sync")
})

test("A raw process binding is refused.", () => {
  native.binding("process_wrap")
})

test("Loading a native addon is refused.", () => {
  process.dlopen({ exports: {} }, marker("addon.node"))
})

test("Replacing the process is refused.", () => {
  native.execve("/bin/echo", ["echo", "ran"])
})
