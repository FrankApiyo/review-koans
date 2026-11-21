import assert from "node:assert/strict"
import { exploit, later, settle, twin } from "#koans"

const fetchUser = async (id: string): Promise<{ id: string }> => {
  await later()
  if (id === "gone") throw new Error("404")
  return { id }
}

const found = async (review: any, id: string): Promise<unknown> => {
  const outcome = await settle(Promise.resolve(review.findUser(id, fetchUser)))
  assert.ok(outcome.done && "value" in outcome)
  return outcome.value
}

const userFound = async (review: any): Promise<void> => {
  assert.deepEqual(await found(review, "u1"), { id: "u1" })
}

const failedFetchIsNull = async (review: any): Promise<void> => {
  assert.equal(await found(review, "gone"), null)
}

export const CASES = [
  twin("a user the fetch finds is returned", userFound),
  exploit("a user whose fetch fails comes back as null", failedFetchIsNull),
]
