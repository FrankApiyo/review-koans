/** Runs the steps in order, one at a time: each step starts after the one before it has finished. */
// >>> guard
export async function migrate(steps: Array<() => Promise<void>>): Promise<void> {
  for (const step of steps) await step()
}
// === wrong: partial — starts every step at once, so a quick later step runs before a slow earlier one finishes
export async function migrate(steps: Array<() => Promise<void>>): Promise<void> {
  await Promise.all(steps.map((s) => s()))
}
// === wrong: partial — starts every step at once and waits for none of them
export async function migrate(steps: Array<() => Promise<void>>): Promise<void> {
  steps.forEach(async (s) => await s())
}
// <<<
