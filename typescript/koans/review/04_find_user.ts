/** The user with `id`, or null when fetching it fails. */
export async function findUser(id: string, fetchUser: FetchUser): Promise<User | null> {
  try {
    return fetchUser(id)
  } catch {
    return null
  }
}

type User = { id: string }
type FetchUser = (id: string) => Promise<User>
