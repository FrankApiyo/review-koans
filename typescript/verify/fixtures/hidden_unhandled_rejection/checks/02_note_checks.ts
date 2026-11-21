import { exploit } from "#koans"

const refused = (review: any): void => {
  review.note("hello", () => Promise.reject("NOTE-REFUSED-3"))
}

export const CASES = [exploit("a refused note", refused)]
