import { expect, test } from "vitest"
import { total } from "./review/spawns.ts"

test("A koan whose review spawns on import.", () => {
  expect(total).toEqual(1)
})
