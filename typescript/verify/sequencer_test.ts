import { expect, test } from "vitest"
import type { TestSpecification } from "vitest/node"
import { PathSequencer } from "../support/sequencer.ts"

const spec = (moduleId: string): TestSpecification => ({ moduleId }) as TestSpecification

test("the sequencer orders files by path, whatever order they arrive in", () => {
  const unsorted = ["/k/02_b_test.ts", "/k/10_z_test.ts", "/k/01_a_test.ts", "/k/Z_upper_test.ts", "/k/00_x_test.ts"]
  const sorted = new PathSequencer().sort(unsorted.map(spec)).map((file) => file.moduleId)
  expect(sorted).toEqual(["/k/00_x_test.ts", "/k/01_a_test.ts", "/k/02_b_test.ts", "/k/10_z_test.ts", "/k/Z_upper_test.ts"])
})

test("the sequencer leaves its input untouched", () => {
  const files = ["/k/02_b_test.ts", "/k/01_a_test.ts"].map(spec)
  new PathSequencer().sort(files)
  expect(files.map((file) => file.moduleId)).toEqual(["/k/02_b_test.ts", "/k/01_a_test.ts"])
})
