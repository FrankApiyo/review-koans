import assert from "node:assert/strict"
import { exploit, twin } from "#koans"

const beforeReload = (review: any): void => {
  assert.equal(review.getTimeout(), 5)
}

const afterReload = (review: any): void => {
  review.reload({ timeout: 10 })
  assert.equal(review.getTimeout(), 10)
}

const latestReloadWins = (review: any): void => {
  review.reload({ timeout: 10 })
  review.reload({ timeout: 20 })
  assert.equal(review.getTimeout(), 20)
}

export const CASES = [
  twin("before any reload, the starting timeout is in force", beforeReload),
  exploit("after a reload, the new timeout is in force", afterReload),
  exploit("after two reloads, the latest timeout is in force", latestReloadWins),
]
