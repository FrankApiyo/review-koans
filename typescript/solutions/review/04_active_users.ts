/** The users `isActive` says are active, in their original order. */
export async function activeUsers(users: User[], isActive: (u: User) => Promise<boolean>): Promise<User[]> {
  const flags = await Promise.all(users.map(isActive))
  return users.filter((_, i) => flags[i])
}

type User = { name: string }
