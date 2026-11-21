import { readFileSync } from "node:fs"

const EXIT_LINE = /^exit (-?\d+)$/m
const STDOUT_MARK = "--- stdout\n"
const STDERR_MARK = "--- stderr\n"
const ERROR_LINE = /^(\w*Error|Error)(: |$)/m
const AT_LINE = /^\s+at .*$/gm
const COURSE_FRAME = /(traces\/[^\s:()]+):(\d+)/

export function read(name: string): string {
  return readFileSync(`traces/${name}.ts.trace`, "utf8")
}

function stderr(name: string): string {
  const text = read(name)
  const start = text.indexOf(STDERR_MARK)
  return start === -1 ? "" : text.slice(start + STDERR_MARK.length)
}

export function stdout(name: string): string {
  const text = read(name)
  const start = text.indexOf(STDOUT_MARK)
  const end = text.indexOf(STDERR_MARK)
  return start === -1 || end === -1 ? "" : text.slice(start + STDOUT_MARK.length, end)
}

export function exitCode(name: string): number {
  const found = EXIT_LINE.exec(read(name))
  if (!found) throw new Error(`traces/${name}.ts.trace has no exit line`)
  return Number(found[1])
}

export function errorName(name: string): string | null {
  return ERROR_LINE.exec(stderr(name))?.[1] ?? null
}

export function frames(name: string): Array<[string, number]> {
  return [...stderr(name).matchAll(AT_LINE)].flatMap(([line]) => {
    const found = COURSE_FRAME.exec(line)
    return found ? [[found[1], Number(found[2])] as [string, number]] : []
  })
}

export function crashFrame(name: string): [string, number] | null {
  return frames(name)[0] ?? null
}
