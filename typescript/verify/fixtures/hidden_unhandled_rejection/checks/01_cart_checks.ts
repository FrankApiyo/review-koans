import assert from "node:assert/strict"
import { exploit, twin } from "#koans"

const saves = (review: any): void => {
  assert.deepEqual(review.save({ id: 1 }, async () => undefined), { id: 1 })
}

const warehouseDown = (review: any): void => {
  review.save({ id: 2 }, async () => {
    throw new Error("WAREHOUSE-DOWN-7")
  })
}

export const CASES = [twin("saving an order", saves), exploit("a warehouse that is down", warehouseDown)]
