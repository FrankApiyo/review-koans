import { test } from "vitest"
import { runChecks } from "#koans"

test("Fix the bug in verify/fixtures/hidden_unhandled_rejection/review/02_note.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "02_note")
})
