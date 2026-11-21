import assert from "node:assert/strict"
import { settle, twin } from "#koans"

const ticks: number[] = []

const watches = (review: any): void => {
  review.watch(() => ticks.push(1))
}

const quiet = async (): Promise<void> => {
  const before = ticks.length
  await settle(new Promise((resolve) => setTimeout(resolve, 50)))
  assert.equal(ticks.length, before)
}

export const CASES = [twin("watching the cart", watches), twin("a quiet cart", quiet)]
