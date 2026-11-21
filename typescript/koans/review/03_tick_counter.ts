import { EventEmitter } from "node:events"

/** Counts the clock's "tick" events between `start` and `stop`; `stop` takes off the listener `start` put on. */
export class TickCounter {
  count = 0
  clock: EventEmitter
  constructor(clock: EventEmitter) { this.clock = clock }
  start() { this.clock.on("tick", this.onTick) }
  stop() { this.clock.off("tick", this.onTick) }
  onTick() { this.count += 1 }
}
