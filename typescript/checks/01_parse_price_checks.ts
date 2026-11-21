import assert from "node:assert/strict"
import { exploit, twin } from "#koans"

const ordinaryPrices = (review: any): void => {
  assert.equal(review.parsePrice("12.50"), 12.5)
  assert.equal(review.parsePrice("0"), 0)
}

const paddedPrice = (review: any): void => {
  assert.equal(review.parsePrice(" 12.50 "), 12.5)
}

const word = (review: any): void => {
  assert.throws(() => review.parsePrice("abc"), RangeError)
}

const numberThenText = (review: any): void => {
  assert.throws(() => review.parsePrice("12px"), RangeError)
}

const emptyText = (review: any): void => {
  assert.throws(() => review.parsePrice(""), RangeError)
}

const spacesOnly = (review: any): void => {
  assert.throws(() => review.parsePrice("  "), RangeError)
}

const infinity = (review: any): void => {
  assert.throws(() => review.parsePrice("Infinity"), RangeError)
  assert.throws(() => review.parsePrice("-Infinity"), RangeError)
}

export const CASES = [
  twin("ordinary prices, zero included", ordinaryPrices),
  twin("spaces around a price are ignored", paddedPrice),
  twin("a word is not a price", word),
  twin("a number followed by other text is not a price", numberThenText),
  exploit("empty text is not a price", emptyText),
  exploit("text of only spaces is not a price", spacesOnly),
  exploit("infinity, either sign, is not a price", infinity),
]
