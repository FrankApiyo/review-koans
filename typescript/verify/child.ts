import { spawnSync } from "node:child_process"
import { fileURLToPath } from "node:url"

export const TYPESCRIPT_DIR = fileURLToPath(new URL("..", import.meta.url))
export const MASTER = `${"-".repeat(31)} The master says ${"-".repeat(32)}`
export const ENLIGHTENMENT = `${"-".repeat(32)} Enlightenment ${"-".repeat(33)}`

const INHERITED = /^(VITEST|KOANS_|FORCE_COLOR$|NODE_OPTIONS$|TEST$)/

function childEnv(dir: string, env: Record<string, string>): NodeJS.ProcessEnv {
  const kept = Object.entries(process.env).filter(([key]) => !INHERITED.test(key))
  return { ...Object.fromEntries(kept), NO_COLOR: "1", KOANS_DIR: dir, ...env }
}

export function runKoans(
  dir: string,
  args: string[] = [],
  env: Record<string, string> = {},
): { code: number; output: string } {
  const done = spawnSync("node_modules/.bin/vitest", ["run", ...args], {
    cwd: TYPESCRIPT_DIR,
    env: childEnv(dir, env),
    encoding: "utf8",
    timeout: 120_000,
  })
  if (done.error) throw done.error
  return { code: done.status ?? -1, output: `${done.stdout}${done.stderr}` }
}
