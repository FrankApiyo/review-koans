import assert from "node:assert/strict"
import { exploit, later, rejects, settle, twin } from "#koans"

const step = (log: string[], name: string, waits: number, fails = false) => async (): Promise<void> => {
  log.push(`start ${name}`)
  for (let left = waits; left > 0; left -= 1) await later()
  if (fails) throw new Error(`${name} failed`)
  log.push(`end ${name}`)
}

const logWhenDone = async (review: any, log: string[], steps: Array<() => Promise<void>>): Promise<string[]> => {
  const outcome = await settle(Promise.resolve(review.migrate(steps)).then(() => [...log]))
  assert.ok(outcome.done && "value" in outcome)
  return outcome.value
}

const quickSteps = async (review: any): Promise<void> => {
  const log: string[] = []
  const steps = [step(log, "create table", 0), step(log, "add column", 0)]
  assert.deepEqual(await logWhenDone(review, log, steps), ["start create table", "end create table", "start add column", "end add column"])
}

const slowFirstStep = async (review: any): Promise<void> => {
  const log: string[] = []
  const steps = [step(log, "create table", 2), step(log, "add column", 0)]
  assert.deepEqual(await logWhenDone(review, log, steps), ["start create table", "end create table", "start add column", "end add column"])
}

const failedStepStops = async (review: any): Promise<void> => {
  const log: string[] = []
  const steps = [step(log, "create table", 1, true), step(log, "add column", 0)]
  await rejects(Promise.resolve().then(() => review.migrate(steps)))
  assert.deepEqual(log, ["start create table"])
}

export const CASES = [
  twin("quick steps each run once, in order", quickSteps),
  exploit("each step starts only after the one before it has finished", slowFirstStep),
  exploit("a step that fails stops the steps after it and fails the migration", failedStepStops),
]
