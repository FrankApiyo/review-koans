import assert from "node:assert/strict"
import { EventEmitter } from "node:events"
import { exploit, twin } from "#koans"

const startedListens = (review: any): void => {
  const clock = new EventEmitter()
  new review.TickCounter(clock).start()
  assert.equal(clock.listenerCount("tick"), 1)
}

const stopRemoves = (review: any): void => {
  const clock = new EventEmitter()
  const counter = new review.TickCounter(clock)
  counter.start()
  counter.stop()
  assert.equal(clock.listenerCount("tick"), 0)
}

const othersStay = (review: any): void => {
  const clock = new EventEmitter()
  const heard: string[] = []
  clock.on("tick", () => heard.push("other"))
  const counter = new review.TickCounter(clock)
  counter.start()
  counter.stop()
  clock.emit("tick")
  assert.equal(clock.listenerCount("tick"), 1)
  assert.deepEqual(heard, ["other"])
}

const eachTickCounted = (review: any): void => {
  const clock = new EventEmitter()
  const counter = new review.TickCounter(clock)
  counter.start()
  clock.emit("tick")
  clock.emit("tick")
  assert.equal(counter.count, 2)
}

const countersApart = (review: any): void => {
  const clock = new EventEmitter()
  const first = new review.TickCounter(clock)
  const second = new review.TickCounter(clock)
  first.start()
  second.start()
  clock.emit("tick")
  first.stop()
  clock.emit("tick")
  assert.deepEqual([first.count, second.count], [1, 2])
}

export const CASES = [
  twin("a started counter listens", startedListens),
  twin("stopping removes the listener", stopRemoves),
  twin("stopping leaves the clock's other listeners in place", othersStay),
  exploit("each tick is counted", eachTickCounted),
  exploit("two counters on one clock each count their own ticks", countersApart),
]
