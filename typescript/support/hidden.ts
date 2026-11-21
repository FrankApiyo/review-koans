import { AssertionError } from "node:assert"
import { statSync } from "node:fs"
import { dirname, join, relative, sep } from "node:path"
import { fileURLToPath, pathToFileURL } from "node:url"
import { vi } from "vitest"
import { type Case, type Settled, macrotask, settle } from "./checks.ts"
import { firstLine } from "./text.ts"
import { drain } from "./time.ts"
import { reviewPath } from "./verdict.ts"

const PASSED = Symbol("passed")
const UNHANDLED = "left a rejection unhandled"
const NEVER_LOADED = "it never finished loading"
const LOAD_LIMIT_MS = 10_000

const realSetTimeout = globalThis.setTimeout
const realClearTimeout = globalThis.clearTimeout

type Cause = string | undefined | typeof PASSED

let imports = 0

export class HiddenCase extends Error {
  override name = "HiddenCase"
  readonly label: string
  readonly kind: Case["kind"]
  readonly reviewPath: string
  override readonly cause: string | undefined

  constructor(label: string, kind: Case["kind"], reviewPath: string, cause?: string) {
    super(`A hidden case still fails: ${label}${cause === undefined ? "" : ` (it ${cause})`}`)
    this.label = label
    this.kind = kind
    this.reviewPath = reviewPath
    this.cause = cause
  }
}

export class ReviewDidNotLoad extends Error {
  override name = "ReviewDidNotLoad"
  readonly reviewPath: string

  constructor(reviewPath: string, error: unknown) {
    super(`${reviewPath} does not load: ${reason(error)}`)
    this.reviewPath = reviewPath
  }
}

function reason(error: unknown): string {
  const line = firstLine(error instanceof Error ? error.message : error)
  if (line !== "") return line
  return error instanceof Error ? error.name : "it threw a non-error value"
}

const isFile = (path: string): boolean => statSync(path, { throwIfNoEntry: false })?.isFile() ?? false

const shown = (path: string): string => relative(process.cwd(), path).split(sep).join("/")

/** The nearest `checks/<stem>_checks.ts` from the koan's folder up to the folder holding `package.json`. */
export function findChecks(koanFile: string, stem: string): string {
  const start = dirname(koanFile)
  for (let folder = start; ; folder = dirname(folder)) {
    const candidate = join(folder, "checks", `${stem}_checks.ts`)
    if (isFile(candidate)) return candidate
    if (isFile(join(folder, "package.json")) || dirname(folder) === folder) break
  }
  throw new Error(`no checks/${stem}_checks.ts between ${shown(start)} and the track root`)
}

function freshImport(file: string): Promise<Record<string, unknown>> {
  imports += 1
  vi.resetModules()
  return import(/* @vite-ignore */ `${pathToFileURL(file).href}?case=${imports}`)
}

async function loadCases(file: string): Promise<Case[]> {
  const cases: unknown = (await import(/* @vite-ignore */ pathToFileURL(file).href)).CASES
  if (!Array.isArray(cases)) throw new TypeError(`${shown(file)} exports no CASES array`)
  return cases
}

const isThenable = (value: unknown): value is PromiseLike<unknown> =>
  (typeof value === "object" || typeof value === "function") &&
  value !== null &&
  typeof (value as { then?: unknown }).then === "function"

async function attempt(file: string, check: Case): Promise<Settled<unknown>> {
  try {
    const result = check.run(await freshImport(file))
    return isThenable(result) ? await settle(Promise.resolve(result)) : { done: true, value: result }
  } catch (error) {
    return { done: true, error }
  }
}

async function cleanUp(): Promise<unknown> {
  if (!vi.isFakeTimers()) return undefined
  try {
    await drain()
    return undefined
  } catch (error) {
    return error
  } finally {
    vi.clearAllTimers()
  }
}

function causeOf(outcome: Settled<unknown>): Cause {
  if (!outcome.done) return undefined
  if (!("error" in outcome)) return PASSED
  const { error } = outcome
  if (error instanceof AssertionError) return undefined
  return error instanceof Error ? `raised ${error.name}` : "threw a non-error value"
}

function claim(reason: unknown): void {
  if ((typeof reason === "object" && reason !== null) || typeof reason === "function") {
    Reflect.set(reason, "koansClaimed", true)
  }
}

function restoreZone(zone: string | undefined): void {
  if (zone === undefined) delete process.env.TZ
  else process.env.TZ = zone
}

async function claiming<T>(work: () => Promise<T>): Promise<{ result: T; unhandled: boolean }> {
  let unhandled = false
  const listener = (reason: unknown): void => {
    claim(reason)
    unhandled = true
  }
  process.prependListener("unhandledRejection", listener)
  try {
    const result = await work()
    await macrotask()
    return { result, unhandled }
  } finally {
    process.removeListener("unhandledRejection", listener)
  }
}

async function runCase(file: string, check: Case): Promise<Cause> {
  const zone = process.env.TZ
  try {
    const { result, unhandled } = await claiming(async () => [await attempt(file, check), await cleanUp()] as const)
    if (unhandled) return UNHANDLED
    const [outcome, leftover] = result
    const cause = causeOf(outcome)
    return cause === PASSED && leftover !== undefined ? causeOf({ done: true, error: leftover }) : cause
  } finally {
    restoreZone(zone)
  }
}

// Wall-clock time bounds only the module loader, whose transforms cross a real process boundary; it never decides a case.
async function loadReview(file: string): Promise<void> {
  let timer: ReturnType<typeof setTimeout> | undefined
  const tooLong = new Promise<never>((_resolve, reject) => {
    timer = realSetTimeout(() => reject(new Error(NEVER_LOADED)), LOAD_LIMIT_MS)
  })
  try {
    await Promise.race([freshImport(file), tooLong])
  } finally {
    realClearTimeout(timer)
  }
}

/** Fails with the label of the first hidden case the review in `review/<stem>.ts` still fails. */
export async function runChecks(koanUrl: string, stem: string): Promise<void> {
  const koanFile = fileURLToPath(koanUrl)
  const file = join(dirname(koanFile), "review", `${stem}.ts`)
  const path = reviewPath(koanFile, `${stem}.ts`)
  const loaded = await claiming(async () => {
    try {
      await loadReview(file)
    } catch (error) {
      return new ReviewDidNotLoad(path, error)
    }
    return loadCases(findChecks(koanFile, stem))
  })
  if (loaded.result instanceof ReviewDidNotLoad) throw loaded.result
  for (const check of loaded.result) {
    const cause = await runCase(file, check)
    if (cause !== PASSED) throw new HiddenCase(check.label, check.kind, path, cause)
  }
}
