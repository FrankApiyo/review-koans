import { spawnSync } from "node:child_process"
import { join } from "node:path"

export const WRITE = 'echo ran > "$1"'

export function marker(name: string): string {
  const dir = process.env.KOANS_MARKER_DIR
  if (!dir) throw new Error("KOANS_MARKER_DIR is not set")
  return join(dir, name)
}

export function attempt(): string {
  try {
    spawnSync("true")
    return "ran"
  } catch (error) {
    return (error as Error).message
  }
}
