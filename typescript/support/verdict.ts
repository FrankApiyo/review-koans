import { createHash } from "node:crypto"
import { readFileSync } from "node:fs"
import { dirname, relative, sep } from "node:path"
import { expect } from "vitest"
import { Blank, __ } from "./blank.ts"

export class Verdict extends Error {
  override name = "Verdict"
  readonly reviewPath: string

  constructor(message: string, reviewPath: string) {
    super(message)
    this.reviewPath = reviewPath
  }
}

const short = (data: string | Buffer): string => createHash("sha256").update(data).digest("hex").slice(0, 10)

export function digest(file: string, answer: number | "fine"): string {
  return short(`${file}:${answer}`)
}

export function reviewPath(koanFile: string, file: string): string {
  const folder = relative(process.cwd(), dirname(koanFile)).split(sep).join("/")
  return folder === "" ? `review/${file}` : `${folder}/review/${file}`
}

const isLine = (answer: unknown): answer is number =>
  typeof answer === "number" && Number.isSafeInteger(answer) && answer > 0

function changed(path: string, sourceDigest: string): boolean {
  try {
    return short(readFileSync(path)) !== sourceDigest
  } catch {
    return true
  }
}

function wrongLine(path: string, sourceDigest: string): string {
  const message = `Not that line. Look again at ${path}.`
  if (!changed(path, sourceDigest)) return message
  return `${message}\n${path} has changed since it was generated, so its line numbers may have moved: git diff ${path} shows how.`
}

function refusal(file: string, answer: unknown, accepted: readonly string[], path: string, sourceDigest: string): string | null {
  if (answer !== "fine" && !isLine(answer)) return `Write "fine", or a line number of ${path} as an integer.`
  if (accepted.includes(digest(file, "fine"))) {
    return answer === "fine" ? null : `Read ${path} again: it is fine. Write "fine".`
  }
  if (answer === "fine") return `Not fine: ${path} has a bug. Write the number of the line where it is.`
  return accepted.includes(digest(file, answer)) ? null : wrongLine(path, sourceDigest)
}

export function verdict(file: string, answer: unknown, digests: string, sourceDigest: string): void {
  const koanFile = expect.getState().testPath
  if (koanFile === undefined) throw new Error("verdict() runs only inside a koan")
  const path = reviewPath(koanFile, file)
  if (answer === __) throw new Blank("verdict", path)
  const refused = refusal(file, answer, digests.split(","), path, sourceDigest)
  if (refused !== null) throw new Verdict(refused, path)
}
