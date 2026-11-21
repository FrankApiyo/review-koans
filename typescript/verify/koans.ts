import { readFileSync } from "node:fs"
import { join } from "node:path"
import { TYPESCRIPT_DIR } from "./child.ts"

export type Koan = { line: number; meditation: string }

const KOAN = /^test\("((?:[^"\\]|\\.)*)"/

export const koansLines = (output: string): string[] => output.split("\n").filter((line) => line.startsWith("KOANS-"))

export function koansIn(file: string): Koan[] {
  return readFileSync(join(TYPESCRIPT_DIR, file), "utf8")
    .split("\n")
    .flatMap((text, index) => {
      const found = KOAN.exec(text)
      return found?.[1] === undefined ? [] : [{ line: index + 1, meditation: found[1] }]
    })
}

export function koanAt(file: string, meditation: string): Koan {
  const koan = koansIn(file).find((each) => each.meditation === meditation)
  if (!koan) throw new Error(`no koan named ${meditation} in ${file}`)
  return koan
}
