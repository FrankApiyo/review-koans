import assert from "node:assert/strict"
import { exploit, twin } from "#koans"

const withEmail = (review: any): void => {
  assert.deepEqual(review.collectErrors({ id: 7, email: "ann@example.com" }), [])
}

const withoutEmail = (review: any): void => {
  const errors = review.collectErrors({ id: 41 })
  assert.equal(errors.length, 1)
  assert.match(errors[0], /\b41\b/)
}

const freshDefault = (review: any): void => {
  review.collectErrors({ id: 1 })
  const errors = review.collectErrors({ id: 2 })
  assert.equal(errors.length, 1)
  assert.match(errors[0], /\b2\b/)
}

const callerListAppended = (review: any): void => {
  const errors = ["0: earlier"]
  const returned = review.collectErrors({ id: 3 }, errors)
  assert.equal(returned, errors)
  assert.equal(errors.length, 2)
  assert.equal(errors[0], "0: earlier")
  assert.match(errors[1], /\b3\b/)
}

export const CASES = [
  twin("a record with an email adds nothing", withEmail),
  twin("a record with no email adds one line naming its id", withoutEmail),
  exploit("each call without a list starts from an empty one", freshDefault),
  exploit("a list the caller passes is the one appended to and returned", callerListAppended),
]
