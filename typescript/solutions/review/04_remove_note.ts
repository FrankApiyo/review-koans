type User = { role: string }
type IsAdmin = (u: User) => Promise<boolean>

/** Deletes note `id` from the store when `isAdmin` says the user is an admin; refuses anyone else with an error. */
export async function removeNote(u: User, store: Set<string>, id: string, isAdmin: IsAdmin): Promise<void> {
  if (!(await isAdmin(u))) throw new Error("forbidden")
  store.delete(id)
}
