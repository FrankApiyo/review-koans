import assert from "node:assert/strict"
import { exploit, twin } from "#koans"

const ownerEdits = (review: any): void => {
  assert.ok(review.canEdit({ id: "u1" }, { ownerId: "u1" }))
}

const otherUserCannot = (review: any): void => {
  assert.ok(!review.canEdit({ id: "u2" }, { ownerId: "u1" }))
  assert.ok(!review.canEdit({ id: "u2" }, {}))
}

const noIdOwnedDoc = (review: any): void => {
  assert.ok(!review.canEdit(undefined, { ownerId: "u1" }))
  assert.ok(!review.canEdit({}, { ownerId: "u1" }))
}

const noSessionUnowned = (review: any): void => {
  assert.ok(!review.canEdit(undefined, {}))
}

const guestUnowned = (review: any): void => {
  assert.ok(!review.canEdit({}, {}))
  assert.ok(!review.canEdit({ id: undefined }, { ownerId: undefined }))
}

export const CASES = [
  twin("the owner can edit", ownerEdits),
  twin("a signed-in user who is not the owner cannot edit", otherUserCannot),
  twin("no one without an id can edit an owned document", noIdOwnedDoc),
  exploit("with no one signed in, a document with no owner cannot be edited", noSessionUnowned),
  exploit("a guest with no id cannot edit a document with no owner", guestUnowned),
]
