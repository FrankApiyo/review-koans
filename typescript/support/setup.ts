import { afterEach, beforeEach, vi } from "vitest"
import { armGuard, disarmGuard, installGuard } from "./guard.ts"
import { mirrorNodeTimers } from "./node_timers.ts"

const ZONE = "America/New_York"
const FAKED = ["setTimeout", "clearTimeout", "setInterval", "clearInterval", "setImmediate", "clearImmediate"] as const

installGuard()
mirrorNodeTimers()

beforeEach(() => {
  vi.useFakeTimers({ toFake: [...FAKED] })
  armGuard()
})

afterEach(() => {
  disarmGuard()
  vi.useRealTimers()
  process.env.TZ = ZONE
})
