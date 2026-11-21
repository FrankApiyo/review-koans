import assert from "node:assert/strict"
import { exploit, twin } from "#koans"

const nothingToAdd = (review: any): void => {
  review.meter.add(4)
  review.addAll([])
  assert.equal(review.meter.total, 4)
}

const eachNumberAdded = (review: any): void => {
  review.addAll([2, 3])
  assert.equal(review.meter.total, 5)
}

const addsToWhatIsThere = (review: any): void => {
  review.meter.add(1)
  review.addAll([2, 3])
  review.addAll([4])
  assert.equal(review.meter.total, 10)
}

export const CASES = [
  twin("adding no numbers leaves the total as it was", nothingToAdd),
  exploit("each number is added to the meter", eachNumberAdded),
  exploit("numbers are added to the total already there", addsToWhatIsThere),
]
