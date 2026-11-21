/** Calls `tick` every 10 ms until the process ends. */
export function watch(tick: () => void): void {
  setInterval(tick, 10)
}
