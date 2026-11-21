/** The users `isActive` says are active, in their original order. */
export async function activeUsers(users: User[], isActive: (u: User) => Promise<boolean>): Promise<User[]> {
  // >>> fix
  return users.filter(async (u) => await isActive(u))
  // === fixed
  const flags = await Promise.all(users.map(isActive))
  return users.filter((_, i) => flags[i])
  // === alt: asks about each user in turn
  const active: User[] = []
  for (const u of users) if (await isActive(u)) active.push(u)
  return active
  // === wrong: refuses — returns no users
  return []
  // === wrong: partial — awaits the filtered array, but the filter already kept every user
  return await users.filter(async (u) => await isActive(u))
  // === wrong: partial — drops the async keyword, but the callback still returns a promise
  return users.filter((u) => isActive(u))
  // === wrong: partial — keeps the answers without waiting for them, so every answer counts as yes
  const flags = users.map(isActive)
  return users.filter((_, i) => flags[i])
  // === wrong: partial — collects users in the order their answers arrive
  const active: User[] = []
  await Promise.all(users.map(async (u) => {
    if (await isActive(u)) active.push(u)
  }))
  return active
  // <<<
}

type User = { name: string }
