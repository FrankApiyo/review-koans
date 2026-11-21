import { test } from "vitest"
import { runChecks } from "#koans"

test("Fix the bug in verify/fixtures/hidden_unhandled_rejection/review/01_cart.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "01_cart")
})
