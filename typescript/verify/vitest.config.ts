import { fileURLToPath } from "node:url"
import { defineConfig } from "vitest/config"

export default defineConfig({
  root: fileURLToPath(new URL("..", import.meta.url)),
  test: {
    include: ["verify/*_test.ts"],
    environment: "node",
    pool: "forks",
    fileParallelism: false,
    sequence: { shuffle: false },
    testTimeout: 120_000,
  },
})
