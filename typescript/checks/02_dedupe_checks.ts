import assert from "node:assert/strict"
import { exploit, twin } from "#koans"

const repeatsDropped = (review: any): void => {
  assert.deepEqual(review.dedupe(["a", "a", "b"]), ["a", "b"])
}

const callbackPerKeptId = (review: any): void => {
  const called: string[] = []
  review.dedupe(["a", "b", "a"], (id: string) => called.push(id))
  assert.deepEqual(called, ["a", "b"])
}

const secondCall = (review: any): void => {
  review.dedupe(["a", "b"])
  assert.deepEqual(review.dedupe(["a", "c"]), ["a", "c"])
}

const afterThrowingCallback = (review: any): void => {
  assert.throws(() =>
    review.dedupe(["a"], () => {
      throw new Error("stop")
    }),
  )
  assert.deepEqual(review.dedupe(["a"]), ["a"])
}

const callFromCallback = (review: any): void => {
  const inner: unknown[] = []
  const outer = review.dedupe(["a", "b", "b"], () => inner.push(review.dedupe(["a"])))
  assert.deepEqual(outer, ["a", "b"])
  assert.deepEqual(inner, [["a"], ["a"]])
}

const callFromCallbackOnLaterId = (review: any): void => {
  assert.deepEqual(review.dedupe(["a", "b"], () => review.dedupe(["b"])), ["a", "b"])
}

export const CASES = [
  twin("repeats within one list are dropped, first seen kept", repeatsDropped),
  twin("the callback runs once for each id kept", callbackPerKeptId),
  exploit("a second call is not affected by the first", secondCall),
  exploit("a call after a callback threw starts fresh", afterThrowingCallback),
  exploit("a call made from the callback and the call around it each get their own result", callFromCallback),
  exploit("a call made from the callback does not change what the outer call returns", callFromCallbackOnLaterId),
]
