/*
Review koans come in three kinds, and each one fails until you answer it.

- Predict: replace `__` with the value that makes the assertion true.
- Review: read the module in `koans/review/`, then replace the `__` in its verdict with
  "fine", or with the number of the line that holds the bug. About one review in five is
  fine. After a bug, the next koan has you fix it in place, and hidden checks run your fix.
- Trace: read a real crash captured in `traces/`, and name its cause and where it came from.

`npm test` stops at the first koan that fails, and its footer says where to work. A blank:

    Meditate on koans/00_how_review_koans_work_test.ts:36

A fix names the file to change and the koan that runs its checks. A failing check shows its
label, never a raw value or the fix:

    A hidden case still fails: an ordinary discount
    ------------------------------- The master says --------------------------------
    Write:        koans/review/00_discount.ts
    Exercised by: koans/00_how_review_koans_work_test.ts:44
        Fix the bug in koans/review/00_discount.ts in place. The hidden checks name what still fails.
    2 of 70 koans answered.

The checks are readable in `checks/`, as the answers are in `solutions/`. Read them only after
a real attempt; reading them first defeats the exercise.

A syntax error in a koan file stops the run, and the footer names the file: fix it, then run
`npm test` again. A fix that loops forever never returns; press Ctrl-C to stop the run.
To start again, run `git checkout -- koans/`.
*/

import { expect, test } from "vitest"
import { __, runChecks, trace, verdict } from "#koans"

test("A predict koan: the blank holds the value that makes the assertion true.", () => {
  expect(40 + 2).toEqual(42)
})

test("Read koans/review/00_discount.ts. Write \"fine\", or the line number of the bug.", () => {
  verdict("00_discount.ts", 3, "ea1005ca1b", "ef452a502a")
})

test("Fix the bug in koans/review/00_discount.ts in place. The hidden checks name what still fails.", async () => {
  await runChecks(import.meta.url, "00_discount")
})

test("Read koans/review/00_cart_total.ts. Write \"fine\", or the line number of the bug.", async () => {
  verdict("00_cart_total.ts", "fine", "adfc30b176", "04cad1b6d2")
  await runChecks(import.meta.url, "00_cart_total")
})

test("Read traces/00_cart_report.ts.trace. Name the error, then the file and line it came from.", () => {
  expect(trace.errorName("00_cart_report")).toEqual("TypeError")
  expect(trace.crashFrame("00_cart_report")).toEqual(["traces/00_cart_report.ts", 2])
})
