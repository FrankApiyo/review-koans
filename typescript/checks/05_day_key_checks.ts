import assert from "node:assert/strict"
import { exploit, inZone, twin } from "#koans"

const utcDay = (review: any): void => {
  inZone("UTC", () => assert.equal(review.dayKey(new Date("2026-01-05T12:00:00Z")), "2026-01-05"))
}

const aheadOfUtc = (review: any): void => {
  inZone("Pacific/Auckland", () => assert.equal(review.dayKey(new Date("2026-03-15T20:00:00Z")), "2026-03-16"))
}

const behindUtc = (review: any): void => {
  inZone("America/Los_Angeles", () => assert.equal(review.dayKey(new Date("2026-03-15T02:00:00Z")), "2026-03-14"))
}

export const CASES = [
  twin("in UTC, the day is written as YYYY-MM-DD", utcDay),
  exploit("in a zone ahead of UTC, a UTC evening is already the next local day", aheadOfUtc),
  exploit("in a zone behind UTC, a UTC early morning is still the previous local day", behindUtc),
]
