import { expect, test } from "vitest"
import { Blank, __, __blank } from "../support/blank.ts"

const VALUE = "Replace __ with the value that makes this true."
const CODE = "Replace __blank() with the code the meditation describes."

const VALUES: unknown[] = [42, "s", [1], { a: 1 }, null, undefined, NaN, -0, new Date("2026-01-02T03:04:05Z"), new Map([[1, 2]])]

function thrown(run: () => unknown): unknown {
  try {
    run()
  } catch (error) {
    return error
  }
  throw new Error("expected the call to throw")
}

function expectValueBlank(error: unknown): void {
  expect(error).toBeInstanceOf(Blank)
  const blank = error as Blank
  expect(blank.name).toBe("Blank")
  expect(blank.kind).toBe("value")
  expect(blank.reviewPath).toBeUndefined()
  expect(blank.message).toBe(VALUE)
}

test("__ fails a toEqual against every kind of value", () => {
  for (const value of VALUES) {
    expectValueBlank(thrown(() => expect(value).toEqual(__)))
  }
})

test("__ fails toStrictEqual too", () => {
  for (const value of VALUES) {
    expectValueBlank(thrown(() => expect(value).toStrictEqual(__)))
  }
})

test("__ prints as __", () => {
  expect(String(__)).toBe("__")
  expect(__.toAsymmetricMatcher()).toBe("__")
})

test("__blank() throws the code message", () => {
  const error = thrown(() => __blank())
  expect(error).toBeInstanceOf(Blank)
  expect((error as Blank).kind).toBe("code")
  expect((error as Blank).message).toBe(CODE)
})

test("-0 and 0 under toEqual", () => {
  expect(-0).toEqual(-0)
  expect(0).toEqual(0)
  expect(() => expect(-0).toEqual(0)).toThrow()
  expect(() => expect(0).toEqual(-0)).toThrow()
})
