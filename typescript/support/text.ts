import { stripVTControlCharacters } from "node:util"

const WRAPPER = /^Transform failed with \d+ errors?:$/

/** The first non-empty line of an ANSI-stripped message, skipping a transform wrapper line. */
export function firstLine(message: unknown): string {
  const lines = stripVTControlCharacters(String(message ?? ""))
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line !== "")
  return (WRAPPER.test(lines[0] ?? "") ? lines[1] : lines[0]) ?? ""
}
