import assert from "node:assert/strict"
import { exploit, inZone, twin } from "#koans"

const localDay = (date: Date): number[] => [date.getFullYear(), date.getMonth() + 1, date.getDate()]

const laterIsLater = (review: any): void => {
  const at = (day: string): number => review.dueDate(day).getTime()
  assert.ok(at("2026-03-15") < at("2026-03-16"))
  assert.ok(at("2026-03-16") < at("2026-04-01"))
}

const aheadOfUtc = (review: any): void => {
  inZone("Asia/Tokyo", () => assert.deepEqual(localDay(review.dueDate("2026-03-15")), [2026, 3, 15]))
  inZone("Pacific/Auckland", () => assert.deepEqual(localDay(review.dueDate("2026-03-15")), [2026, 3, 15]))
}

const behindUtc = (review: any): void => {
  inZone("America/New_York", () => assert.deepEqual(localDay(review.dueDate("2026-03-15")), [2026, 3, 15]))
  inZone("America/New_York", () => assert.deepEqual(localDay(review.dueDate("2026-04-15")), [2026, 4, 15]))
}

const yearEnd = (review: any): void => {
  inZone("UTC", () => assert.deepEqual(localDay(review.dueDate("2026-12-31")), [2026, 12, 31]))
}

export const CASES = [
  twin("a later day comes after an earlier one", laterIsLater),
  exploit("in a zone ahead of UTC, the date falls on the day given", aheadOfUtc),
  exploit("in a zone behind UTC, the date falls on the day given", behindUtc),
  exploit("the last day of a year stays in that year", yearEnd),
]
