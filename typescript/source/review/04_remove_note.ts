type User = { role: string }
type IsAdmin = (u: User) => Promise<boolean>

/** Deletes note `id` from the store when `isAdmin` says the user is an admin; refuses anyone else with an error. */
export async function removeNote(u: User, store: Set<string>, id: string, isAdmin: IsAdmin): Promise<void> {
  // >>> fix
  if (!isAdmin(u)) throw new Error("forbidden")
  // === fixed
  if (!(await isAdmin(u))) throw new Error("forbidden")
  // === alt: waits for the answer in a variable first
  const ok = await isAdmin(u)
  if (!ok) throw new Error("forbidden")
  // === wrong: refuses — refuses every user
  throw new Error("forbidden")
  // === wrong: partial — checks the answer in a callback nobody waits for, so the note is deleted first and the refusal goes unhandled
  isAdmin(u).then((ok) => {
    if (!ok) throw new Error("forbidden")
  })
  // === wrong: partial — compares the promise with false, which a promise never equals
  if (isAdmin(u) === false) throw new Error("forbidden")
  // <<<
  store.delete(id)
}
