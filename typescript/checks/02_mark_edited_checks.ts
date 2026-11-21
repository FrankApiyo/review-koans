import assert from "node:assert/strict"
import { exploit, twin } from "#koans"

const draft = () => ({ title: "launch", meta: { tags: ["news"], due: new Date("2026-03-15T10:00:00Z") } })

const copyEdited = (review: any): void => {
  const next = review.markEdited(draft())
  assert.equal(next.title, "launch")
  assert.deepEqual(next.meta.tags, ["news", "edited"])
}

const draftUnchanged = (review: any): void => {
  const original = draft()
  review.markEdited(original)
  assert.deepEqual(original.meta.tags, ["news"])
}

const dueStillADate = (review: any): void => {
  const original = draft()
  const next = review.markEdited(original)
  assert.ok(next.meta.due instanceof Date)
  assert.equal(next.meta.due.getTime(), original.meta.due.getTime())
}

export const CASES = [
  twin("the copy holds the draft's tags plus the edit", copyEdited),
  exploit("the draft's own tags are left as they were", draftUnchanged),
  exploit("the copy's due date is still a date for the same moment", dueStillADate),
]
