import assert from "node:assert/strict"
import { exploit, later, settle, twin } from "#koans"

const repo = () => {
  const saved: string[] = []
  const save = async (id: string): Promise<void> => {
    for (let left = id.length; left > 0; left -= 1) await later()
    saved.push(id)
  }
  return { saved, save }
}

const savedWhenDone = async (review: any, ids: string[]): Promise<string[]> => {
  const r = repo()
  const outcome = await settle(Promise.resolve(review.saveAll(r, ids)).then(() => [...r.saved].sort()))
  assert.ok(outcome.done && "value" in outcome)
  return outcome.value
}

const emptyList = async (review: any): Promise<void> => {
  assert.deepEqual(await savedWhenDone(review, []), [])
}

const everyIdSaved = async (review: any): Promise<void> => {
  assert.deepEqual(await savedWhenDone(review, ["bb", "a", "ccc"]), ["a", "bb", "ccc"])
}

export const CASES = [
  twin("an empty list finishes without saving anything", emptyList),
  exploit("every id is saved by the time saveAll finishes", everyIdSaved),
]
