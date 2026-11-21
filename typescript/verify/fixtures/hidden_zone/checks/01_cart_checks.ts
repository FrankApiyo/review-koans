import assert from "node:assert/strict"
import { twin } from "#koans"

const moves = (review: any): void => {
  review.moveToWarehouse()
}

const courseZone = (): void => {
  assert.equal(process.env.TZ, "America/New_York")
}

export const CASES = [twin("moving to the warehouse", moves), twin("the zone after a move", courseZone)]
