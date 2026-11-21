import { EventEmitter } from "node:events"

/** Counts the clock's "tick" events between `start` and `stop`; `stop` takes off the listener `start` put on. */
export class TickCounter {
  count = 0
  clock: EventEmitter
  constructor(clock: EventEmitter) { this.clock = clock }
  // >>> fix
  start() { this.clock.on("tick", this.onTick) }
  stop() { this.clock.off("tick", this.onTick) }
  onTick() { this.count += 1 }
  // === fixed
  start() { this.clock.on("tick", this.onTick) }
  stop() { this.clock.off("tick", this.onTick) }
  onTick = () => { this.count += 1 }
  // === alt: keeps one arrow listener that calls the method on this counter
  listener = () => this.onTick()
  start() { this.clock.on("tick", this.listener) }
  stop() { this.clock.off("tick", this.listener) }
  onTick() { this.count += 1 }
  // === alt: binds the method once and adds and removes that one bound function
  boundTick = this.onTick.bind(this)
  start() { this.clock.on("tick", this.boundTick) }
  stop() { this.clock.off("tick", this.boundTick) }
  onTick() { this.count += 1 }
  // === wrong: refuses — never listens to the clock
  start() {}
  stop() { this.clock.off("tick", this.onTick) }
  onTick() { this.count += 1 }
  // === wrong: partial — each bind makes a new function, so stop removes one that was never added
  start() { this.clock.on("tick", this.onTick.bind(this)) }
  stop() { this.clock.off("tick", this.onTick.bind(this)) }
  onTick() { this.count += 1 }
  // === wrong: partial — the listener returns the method without calling it, so no tick is counted
  listener = () => this.onTick
  start() { this.clock.on("tick", this.listener) }
  stop() { this.clock.off("tick", this.listener) }
  onTick() { this.count += 1 }
  // === wrong: partial — stop removes every tick listener on the clock, not only its own
  start() { this.clock.on("tick", () => this.onTick()) }
  stop() { this.clock.removeAllListeners("tick") }
  onTick() { this.count += 1 }
  // <<<
}
