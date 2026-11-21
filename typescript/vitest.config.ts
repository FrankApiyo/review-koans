import { defineConfig } from "vitest/config"
import { KoanReporter } from "./support/reporter.ts"
import { PathSequencer } from "./support/sequencer.ts"

export default defineConfig({
  test: {
    include: [`${process.env.KOANS_DIR ?? "koans"}/**/[0-9][0-9]_*_test.ts`],
    environment: "node",
    pool: "forks",
    fileParallelism: false,
    bail: process.env.KOANS_VERIFY === "1" ? 0 : 1,
    sequence: { sequencer: PathSequencer, shuffle: false },
    reporters: [new KoanReporter()],
    includeTaskLocation: true,
    setupFiles: ["./support/setup.ts"],
    env: { TZ: "America/New_York" },
    testTimeout: 30_000,
    hookTimeout: 30_000,
    onUnhandledError: (error) => (error as { koansClaimed?: unknown }).koansClaimed !== true,
  },
})
