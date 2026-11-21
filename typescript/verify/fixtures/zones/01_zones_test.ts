import { expect, test } from "vitest"
import { inZone } from "#koans"

const NOON_UTC = Date.UTC(2024, 0, 1, 12)

test("TZ is America/New_York inside a koan.", () => {
  expect(process.env.TZ).toBe("America/New_York")
  expect(new Date(NOON_UTC).getHours()).toBe(7)
  expect(new Date(2024, 0, 1).toISOString()).toBe("2024-01-01T05:00:00.000Z")
})

test("inZone runs in another zone and restores it.", () => {
  expect(inZone("Asia/Tokyo", () => new Date(NOON_UTC).getHours())).toBe(21)
  expect(inZone("Pacific/Auckland", () => new Date(2024, 0, 1).toISOString())).toBe("2023-12-31T11:00:00.000Z")
  expect(process.env.TZ).toBe("America/New_York")
  expect(new Date(NOON_UTC).getHours()).toBe(7)
})

test("inZone restores the zone after its function throws.", () => {
  expect(() =>
    inZone("Asia/Tokyo", () => {
      throw new RangeError("inside")
    }),
  ).toThrow(RangeError)
  expect(process.env.TZ).toBe("America/New_York")
  expect(new Date(NOON_UTC).getHours()).toBe(7)
})

test("inZone refuses an async function.", () => {
  expect(() => inZone("Asia/Tokyo", async () => 1)).toThrow(new TypeError("inZone takes a synchronous function"))
  expect(process.env.TZ).toBe("America/New_York")
})

test("A koan that moves the zone.", () => {
  process.env.TZ = "Asia/Tokyo"
  expect(new Date(NOON_UTC).getHours()).toBe(21)
})

test("The next koan is back in New York.", () => {
  expect(process.env.TZ).toBe("America/New_York")
  expect(new Date(NOON_UTC).getHours()).toBe(7)
})

test("Numbers, sorting and ISO dates ignore the machine locale.", () => {
  expect(String(1234.5)).toBe("1234.5")
  expect(["b", "ä", "a"].sort()).toEqual(["a", "b", "ä"])
  expect(new Date("2024-03-10T12:00:00Z").toISOString()).toBe("2024-03-10T12:00:00.000Z")
})

test("Collation follows the pinned locale, not the machine's.", () => {
  expect(new Intl.Collator().resolvedOptions().locale).toBe("en-US")
  expect("ä".localeCompare("z")).toBe(-1)
})
