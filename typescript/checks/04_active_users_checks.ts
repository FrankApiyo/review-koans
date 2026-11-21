import assert from "node:assert/strict"
import { exploit, later, settle, twin } from "#koans"

type User = { name: string; active: boolean; slow?: boolean }

const gate = () => {
  let open = (): void => {}
  const shut = new Promise<void>((resolve) => {
    open = resolve
  })
  return { shut, open }
}

const isActive = async (u: User): Promise<boolean> => {
  await later()
  if (u.slow === true) await later()
  return u.active
}

const names = (users: unknown): unknown => (Array.isArray(users) ? users.map((u: User) => u?.name) : users)

const namesOf = async (review: any, users: User[]): Promise<unknown> => {
  const outcome = await settle(Promise.resolve(review.activeUsers(users, isActive)).then(names))
  assert.ok(outcome.done && "value" in outcome)
  return outcome.value
}

const allActive = async (review: any): Promise<void> => {
  const users = [{ name: "ann", active: true }, { name: "cy", active: true }]
  assert.deepEqual(await namesOf(review, users), ["ann", "cy"])
}

const inactiveLeftOut = async (review: any): Promise<void> => {
  const users = [{ name: "ann", active: true }, { name: "bob", active: false }]
  assert.deepEqual(await namesOf(review, users), ["ann"])
}

const originalOrder = async (review: any): Promise<void> => {
  const users = [{ name: "ann", active: true, slow: true }, { name: "bob", active: false }, { name: "cy", active: true }]
  assert.deepEqual(await namesOf(review, users), ["ann", "cy"])
}

const waitsForAnAnswer = async (review: any): Promise<void> => {
  const { shut, open } = gate()
  const slowIsActive = async (u: User): Promise<boolean> => {
    await shut
    return u.active
  }
  const users = [{ name: "ann", active: true }, { name: "bob", active: false }]
  const done = Promise.resolve(review.activeUsers(users, slowIsActive)).then(names)
  assert.equal((await settle(done)).done, false)
  open()
  const outcome = await settle(done)
  assert.ok(outcome.done && "value" in outcome)
  assert.deepEqual(outcome.value, ["ann"])
}

export const CASES = [
  twin("a list of active users comes back whole, in order", allActive),
  exploit("an inactive user is left out", inactiveLeftOut),
  exploit("the active users keep their original order", originalOrder),
  exploit("activeUsers keeps waiting while an answer is still coming", waitsForAnAnswer),
]
