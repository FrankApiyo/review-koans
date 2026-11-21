/** Runs the steps in order, one at a time: each step starts after the one before it has finished. */
export async function migrate(steps: Array<() => Promise<void>>): Promise<void> {
  for (const step of steps) await step()
}
