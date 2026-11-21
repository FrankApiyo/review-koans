type Booking = { room: string; startsAt: Date }

function cloneBooking(booking: Booking): Booking {
  return JSON.parse(JSON.stringify(booking))
}

function minutesUntil(booking: Booking, now: Date): number {
  return (booking.startsAt.getTime() - now.getTime()) / 60_000
}

const original: Booking = { room: "B2", startsAt: new Date("2026-03-15T10:00:00Z") }
console.log(minutesUntil(original, new Date("2026-03-15T09:00:00Z")))
const draft = cloneBooking(original)
console.log(minutesUntil(draft, new Date("2026-03-15T09:00:00Z")))
