/** The users `isActive` says are active, in their original order. */
export async function activeUsers(users: User[], isActive: (u: User) => Promise<boolean>): Promise<User[]> {
  return users.filter(async (u) => await isActive(u))
}

type User = { name: string }
