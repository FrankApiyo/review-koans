import assert from "node:assert/strict"
import { exploit, later, rejects, settle, twin } from "#koans"

const isAdmin = async (u: { role: string }): Promise<boolean> => {
  await later()
  return u.role === "admin"
}

const adminDeletes = async (review: any): Promise<void> => {
  const store = new Set(["n1", "n2"])
  const done = Promise.resolve(review.removeNote({ role: "admin" }, store, "n1", isAdmin)).then(() => [...store])
  const outcome = await settle(done)
  assert.ok(outcome.done && "value" in outcome)
  assert.deepEqual(outcome.value, ["n2"])
}

const viewerRefused = async (review: any): Promise<void> => {
  const store = new Set(["n1"])
  await rejects(Promise.resolve().then(() => review.removeNote({ role: "viewer" }, store, "n1", isAdmin)))
  assert.ok(store.has("n1"))
}

export const CASES = [
  twin("an admin deletes the note", adminDeletes),
  exploit("a viewer does not delete the note and is refused", viewerRefused),
]
