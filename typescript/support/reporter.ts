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

function firstLine(message: string): string {
  return stripVTControlCharacters(message).split("\n").find((line) => line.trim() !== "")?.trim() ?? ""
}

const errorName = (error: SerializedError): string => error.name ?? "Error"

function kindOf(error: SerializedError): string {
  const name = errorName(error)
  return name === "HiddenCase" ? `HiddenCase:${String(error.kind)}` : name
}

function messageOf(error: SerializedError): string {
  const name = errorName(error)
  return OWN.has(name) ? error.message : `${name}: ${firstLine(error.message)}`
}

function writeOf(error: SerializedError): string | null {
  return WRITES.has(errorName(error)) && typeof error.reviewPath === "string" ? error.reviewPath : null
}

function frameLine(error: SerializedError, moduleId: string): number | undefined {
  return error.stacks?.find((frame) => frame.file === moduleId)?.line
}

function escaped(text: string): string {
  return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
}

function loadLine(error: SerializedError, module: TestModule): number | null {
  const name = module.moduleId.split("/").pop() ?? ""
  const named = new RegExp(`${escaped(name)}:(\\d+)`).exec(stripVTControlCharacters(error.message))
  return named ? Number(named[1]) : (frameLine(error, module.moduleId) ?? null)
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
      const [loadError] = module.errors()
      if (loadError !== undefined && tests.length === 0) failures.push(this.loadFailure(loadError, module, path))
      for (const test of tests) {
        const outcome = this.outcome(test, path)
        if (outcome === null) continue
        finished.push(outcome.finished)
        if (outcome.failed !== null) failures.push(outcome.failed)
      }
    }
    const first = [...failures].sort((a, b) => byPlace(a.failure, b.failure))[0] ?? null
    const lines = unhandledErrors.map((error) => `${errorName(error)}: ${firstLine(error.message)}`)
    if (modules.length > 0) {
      const passed = finished.filter((done) => done.kind === "ok").length
      const footer = render(passed, total(dirname(modules[0].moduleId)), finished.length, first?.failure ?? null)
      if (footer !== "") lines.push(footer)
    }
    if (verifying()) lines.push(...verifyLines(finished, first, unhandledErrors))
    if (lines.length > 0) this.write(`\n${lines.join("\n")}\n`)
  }

  private relative(moduleId: string): string {
    return relative(process.cwd(), moduleId).split(sep).join("/")
  }

  private loadFailure(error: SerializedError, module: TestModule, path: string): Failed {
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

function verifyLines(finished: Finished[], first: Failed | null, unhandled: ReadonlyArray<SerializedError>): string[] {
  const tests = [...finished].sort(byPlace).map((done) => `KOANS-TEST ${done.kind} ${done.path}:${done.line}`)
  return [...tests, resultLine(first, unhandled)]
}

function resultLine(first: Failed | null, unhandled: ReadonlyArray<SerializedError>): string {
  if (first !== null) return `KOANS-RESULT ${first.kind} ${first.failure.path}:${first.failure.line ?? 0}`
  const [error] = unhandled
  return error === undefined ? "KOANS-RESULT ok" : `KOANS-RESULT ${errorName(error)}`
}
