import { dirname, relative, sep } from "node:path"
import { stripVTControlCharacters } from "node:util"
import type { Reporter, SerializedError, TestCase, TestModule, Vitest } from "vitest/node"
import { type Failure, render, total } from "./footer.ts"

type Finished = { kind: string; path: string; line: number }
type Failed = { kind: string; failure: Failure }

const OWN = new Set(["Blank", "Verdict", "HiddenCase", "ReviewDidNotLoad"])
const WRITES = new Set(["HiddenCase", "ReviewDidNotLoad"])

const verifying = (): boolean => process.env.KOANS_VERIFY === "1"

const byText = (a: string, b: string): number => (a < b ? -1 : a > b ? 1 : 0)

const byPlace = (a: { path: string; line: number | null }, b: { path: string; line: number | null }): number =>
  byText(a.path, b.path) || (a.line ?? 0) - (b.line ?? 0)

const WRAPPER = /^Transform failed with \d+ errors?:$/
const NO_MATCH = "No koan file matches. Check the path and the file name, for example: npx vitest run koans/01_equality_test.ts"

function firstLine(message: string): string {
  const lines = stripVTControlCharacters(message)
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line !== "")
  return (WRAPPER.test(lines[0] ?? "") ? lines[1] : lines[0]) ?? ""
}

const errorName = (error: SerializedError): string => error.name ?? "Error"

function kindOf(error: SerializedError): string {
  const name = errorName(error)
  return name === "HiddenCase" ? `HiddenCase:${String(error.kind)}` : name
}

function messageOf(error: SerializedError): string {
  const name = errorName(error)
  return OWN.has(name) ? error.message : describe(error)
}

function writeOf(error: SerializedError): string | null {
  return WRITES.has(errorName(error)) && typeof error.reviewPath === "string" ? error.reviewPath : null
}

function frameLine(error: SerializedError, moduleId: string): number | undefined {
  const parsed = error.stacks?.find((frame) => frame.file === moduleId)?.line
  if (parsed !== undefined || typeof error.stack !== "string") return parsed
  const raw = new RegExp(`[\\s(](?:file://)?${escaped(moduleId)}:(\\d+):\\d+`).exec(error.stack)
  return raw ? Number(raw[1]) : undefined
}

function escaped(text: string): string {
  return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
}

export function messageLine(message: string, fileName: string): number | null {
  const named = new RegExp(`(?:^|[\\s/[(])${escaped(fileName)}:(\\d+)`, "m").exec(stripVTControlCharacters(message))
  return named ? Number(named[1]) : null
}

function loadLine(error: SerializedError, module: TestModule): number | null {
  const fileName = module.moduleId.split("/").pop() ?? ""
  return messageLine(error.message, fileName) ?? frameLine(error, module.moduleId) ?? null
}

export class KoanReporter implements Reporter {
  private write: (text: string) => void = (text) => process.stdout.write(text)

  onInit(vitest: Vitest): void {
    this.write = (text) => vitest.logger.outputStream.write(text)
  }

  onTestRunEnd(testModules: ReadonlyArray<TestModule>, unhandledErrors: ReadonlyArray<SerializedError>): void {
    const modules = [...testModules].sort((a, b) => byText(a.moduleId, b.moduleId))
    const finished: Finished[] = []
    const failures: Failed[] = []
    for (const module of modules) {
      const path = this.relative(module.moduleId)
      const tests = [...module.children.allTests()]
      const [moduleError] = module.errors()
      if (moduleError !== undefined) failures.push(this.moduleFailure(moduleError, module, path, tests.length === 0))
      for (const test of tests) {
        const outcome = this.outcome(test, path)
        if (outcome === null) continue
        finished.push(outcome.finished)
        if (outcome.failed !== null) failures.push(outcome.failed)
      }
    }
    const located = unhandledErrors.map((error) => this.unhandledFailure(error, modules))
    const unlocated = unhandledErrors.filter((_error, index) => located[index] === null)
    const all = [...failures, ...located.filter((failed): failed is Failed => failed !== null)]
    const first = all.sort((a, b) => byPlace(a.failure, b.failure))[0] ?? null
    const lines = [...unlocated.map(describe), ...footerLines(modules, finished, first, unlocated.length > 0)]
    if (verifying()) lines.push(...verifyLines(finished, first, unlocated))
    this.write(`\n${lines.join("\n")}\n`)
  }

  private unhandledFailure(error: SerializedError, modules: ReadonlyArray<TestModule>): Failed | null {
    for (const module of modules) {
      const line = frameLine(error, module.moduleId)
      if (line !== undefined) return { kind: errorName(error), failure: foreign(error, this.relative(module.moduleId), line) }
    }
    return null
  }

  private relative(moduleId: string): string {
    return relative(process.cwd(), moduleId).split(sep).join("/")
  }

  private moduleFailure(error: SerializedError, module: TestModule, path: string, unloaded: boolean): Failed {
    if (!unloaded) return { kind: errorName(error), failure: foreign(error, path, frameLine(error, module.moduleId) ?? null) }
    const failure = {
      path,
      line: loadLine(error, module),
      meditation: null,
      message: `${path} does not load: ${firstLine(error.message)}`,
      write: null,
    }
    return { kind: "LoadError", failure }
  }

  private outcome(test: TestCase, path: string): { finished: Finished; failed: Failed | null } | null {
    const result = test.result()
    const line = test.location?.line ?? 0
    if (result.state === "passed") return { finished: { kind: "ok", path, line }, failed: null }
    const error = result.state === "failed" ? result.errors[0] : undefined
    if (error === undefined) return null
    const kind = kindOf(error)
    const failure = {
      path,
      line: frameLine(error, test.module.moduleId) ?? line,
      meditation: test.name,
      message: messageOf(error),
      write: writeOf(error),
    }
    return { finished: { kind, path, line }, failed: { kind, failure } }
  }
}

const describe = (error: SerializedError): string => `${errorName(error)}: ${firstLine(error.message)}`

function foreign(error: SerializedError, path: string, line: number | null): Failure {
  return { path, line, meditation: null, message: describe(error), write: null }
}

function footerLines(
  modules: ReadonlyArray<TestModule>,
  finished: Finished[],
  first: Failed | null,
  errored: boolean,
): string[] {
  if (modules.length === 0) return errored ? [] : [NO_MATCH]
  const passed = finished.filter((done) => done.kind === "ok").length
  const koans = total(dirname(modules[0].moduleId))
  if (first === null && errored) return [`${passed} of ${koans} koans answered.`]
  const footer = render(passed, koans, finished.length, first?.failure ?? null)
  return footer === "" ? [] : [footer]
}

function verifyLines(finished: Finished[], first: Failed | null, unhandled: ReadonlyArray<SerializedError>): string[] {
  const tests = [...finished].sort(byPlace).map((done) => `KOANS-TEST ${done.kind} ${done.path}:${done.line}`)
  return [...tests, resultLine(first, unhandled)]
}

function resultLine(first: Failed | null, unhandled: ReadonlyArray<SerializedError>): string {
  if (first !== null) return `KOANS-RESULT ${first.kind} ${first.failure.path}:${first.failure.line ?? 0}`
  const [error] = unhandled
  return error === undefined ? "KOANS-RESULT ok" : `KOANS-RESULT ${errorName(error)}`
}
