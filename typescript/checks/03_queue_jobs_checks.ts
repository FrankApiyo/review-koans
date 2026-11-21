import assert from "node:assert/strict"
import { exploit, twin } from "#koans"

const noJobs = (review: any): void => {
  const ran: unknown[] = []
  const queue = review.queueJobs([], (job: unknown) => ran.push(job))
  queue.forEach((entry: () => void) => entry())
  assert.deepEqual([queue.length, ran], [0, []])
}

const entryPerJob = (review: any): void => {
  assert.equal(review.queueJobs(["a", "b", "c"], () => {}).length, 3)
}

const nothingRunsEarly = (review: any): void => {
  const ran: unknown[] = []
  review.queueJobs(["a", "b"], (job: unknown) => ran.push(job))
  assert.deepEqual(ran, [])
}

const runsInOrder = (review: any): void => {
  const ran: unknown[] = []
  const queue = review.queueJobs(["a", "b"], (job: unknown) => ran.push(job))
  queue.forEach((entry: () => void) => entry())
  assert.deepEqual(ran, ["a", "b"])
}

const eachEntryOwnJob = (review: any): void => {
  const ran: unknown[] = []
  const queue = review.queueJobs(["a", "b", "c"], (job: unknown) => ran.push(job))
  queue[2]()
  queue[0]()
  queue[0]()
  queue[1]()
  assert.deepEqual(ran, ["c", "a", "a", "b"])
}

export const CASES = [
  twin("no jobs, no entries", noJobs),
  twin("one entry per job", entryPerJob),
  twin("no job runs before its entry is called", nothingRunsEarly),
  exploit("running the queue runs the jobs in order", runsInOrder),
  exploit("each entry runs its own job, whenever it is called", eachEntryOwnJob),
]
