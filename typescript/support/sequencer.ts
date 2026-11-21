import type { TestSequencer, TestSpecification } from "vitest/node"

const byPath = (a: TestSpecification, b: TestSpecification): number =>
  a.moduleId < b.moduleId ? -1 : a.moduleId > b.moduleId ? 1 : 0

export class PathSequencer implements TestSequencer {
  sort(files: TestSpecification[]): TestSpecification[] {
    return [...files].sort(byPath)
  }

  shard(files: TestSpecification[]): TestSpecification[] {
    return files
  }
}
