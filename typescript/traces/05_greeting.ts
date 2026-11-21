type User = { id: string; profile: { displayName: string } }

function parseUser(body: string): User {
  return JSON.parse(body) as User
}

function greeting(body: string): string {
  const user = parseUser(body)
  return `Hello, ${user.profile.displayName.trim()}`
}

console.log(greeting('{"id": "u1", "profile": {"display_name": "Ann"}}'))
