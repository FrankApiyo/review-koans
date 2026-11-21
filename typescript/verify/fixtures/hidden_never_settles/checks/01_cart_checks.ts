import assert from "node:assert/strict"
import { exploit } from "#koans"

const finishes = async (review: any): Promise<void> => {
  assert.equal(await review.reserve("PEAR-7"), "PEAR-7")
}

export const CASES = [exploit("a reservation that never finishes", finishes)]
