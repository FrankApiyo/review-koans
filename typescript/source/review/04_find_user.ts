/** The user with `id`, or null when fetching it fails. */
export async function findUser(id: string, fetchUser: FetchUser): Promise<User | null> {
  try {
    // >>> fix
    return fetchUser(id)
    // === fixed
    return await fetchUser(id)
    // === alt: turns a failed fetch into null on the promise itself
    return fetchUser(id).catch(() => null)
    // === wrong: refuses — never returns the user
    return null
    // === wrong: partial — names the promise first, but still returns it without waiting
    const p = fetchUser(id)
    return p
    // === wrong: partial — chains a callback that changes nothing, so the failure still arrives after the try
    return fetchUser(id).then((u) => u)
    // <<<
  } catch {
    return null
  }
}

type User = { id: string }
type FetchUser = (id: string) => Promise<User>
