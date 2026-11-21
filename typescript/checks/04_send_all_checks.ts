import assert from "node:assert/strict"
import { exploit, later, settle, twin } from "#koans"

const gate = () => {
  let open = (): void => {}
  const shut = new Promise<void>((resolve) => {
    open = resolve
  })
  return { shut, open }
}

const send = async (id: string): Promise<void> => {
  await later()
  if (id.startsWith("x")) throw new Error(`bounce ${id}`)
}

const sorted = (ids: unknown): unknown => (Array.isArray(ids) ? [...ids].sort() : ids)

const asResolved = (report: unknown): unknown => {
  if (typeof report !== "object" || report === null) return report
  const { ok, failed } = report as { ok?: unknown; failed?: unknown }
  return { ok: sorted(ok), failed: sorted(failed) }
}

const reportFor = async (review: any, ids: string[]): Promise<unknown> => {
  const outcome = await settle(Promise.resolve(review.sendAll(ids, send)).then(asResolved))
  assert.ok(outcome.done && "value" in outcome)
  return outcome.value
}

const allGood = async (review: any): Promise<void> => {
  assert.deepEqual(await reportFor(review, ["b", "a"]), { ok: ["a", "b"], failed: [] })
}

const oneFails = async (review: any): Promise<void> => {
  assert.deepEqual(await reportFor(review, ["a", "x1", "b"]), { ok: ["a", "b"], failed: ["x1"] })
}

const waitsForASend = async (review: any): Promise<void> => {
  const { shut, open } = gate()
  const slowSend = async (id: string): Promise<void> => {
    await shut
    if (id.startsWith("x")) throw new Error(`bounce ${id}`)
  }
  const done = Promise.resolve(review.sendAll(["a", "x1"], slowSend)).then(asResolved)
  assert.equal((await settle(done)).done, false)
  open()
  const outcome = await settle(done)
  assert.ok(outcome.done && "value" in outcome)
  assert.deepEqual(outcome.value, { ok: ["a"], failed: ["x1"] })
}

export const CASES = [
  twin("when every send succeeds, every id is reported ok", allGood),
  exploit("a failed send is reported as failed and the others as ok", oneFails),
  exploit("sendAll keeps waiting while a send is still running", waitsForASend),
]
