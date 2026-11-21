import { readFileSync, readdirSync } from "node:fs"
import { join } from "node:path"

export type Failure = {
  path: string
  line: number | null
  meditation: string | null
  message: string
  write: string | null
}

const WIDTH = 80
const KOAN_FILE = /^\d\d_.*_test\.ts$/
const KOAN_HEAD = /^test\("/gm

export function separator(title: string): string {
  const padded = ` ${title} `
  const fill = WIDTH - padded.length
  const left = Math.floor(fill / 2)
  return "-".repeat(left) + padded + "-".repeat(fill - left)
}

function where(failure: Failure): string {
  const at = failure.line === null ? failure.path : `${failure.path}:${failure.line}`
  if (failure.write === null) return `Meditate on ${at}`
  return `Write:        ${failure.write}\nExercised by: ${at}`
}

function failed(passed: number, total: number, failure: Failure): string {
  const meditation =
    failure.meditation === null ? [] : failure.meditation.split("\n").map((line) => `    ${line}`)
  return [failure.message, separator("The master says"), where(failure), ...meditation, `${passed} of ${total} koans answered.`].join("\n")
}

export function render(passed: number, total: number, ran: number, failure: Failure | null): string {
  if (failure !== null) return failed(passed, total, failure)
  if (ran === 0) return ""
  if (ran >= total && passed === total) {
    return `${separator("Enlightenment")}\nAll ${total} koans pass. Start again with: git checkout -- koans/`
  }
  return `${passed} of ${total} koans answered. Run the whole suite for the rest.`
}

export function total(folder: string): number {
  return readdirSync(folder)
    .filter((name) => KOAN_FILE.test(name))
    .reduce((sum, name) => sum + (readFileSync(join(folder, name), "utf8").match(KOAN_HEAD)?.length ?? 0), 0)
}
