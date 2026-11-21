/** Whether `user` may edit `doc`: only a signed-in user whose id is the document's owner id. `user` is undefined when no one is signed in, and a guest has no id. */
export const canEdit = (user: { id?: string } | undefined, doc: { ownerId?: string }): boolean =>
  // >>> fix
  doc.ownerId === user?.id
  // === fixed
  user?.id !== undefined && doc.ownerId === user.id
  // === alt: requires the user's id to be text before comparing it
  typeof user?.id === "string" && doc.ownerId === user.id
  // === alt: requires the document to have an owner before comparing
  doc.ownerId !== undefined && doc.ownerId === user?.id
  // === wrong: refuses — no one may edit anything
  false
  // === wrong: partial — turns away a missing user but not a guest with no id
  user ? doc.ownerId === user.id : false
  // === wrong: partial — still compares a guest's missing id with a missing owner
  Boolean(user && doc.ownerId === user.id)
  // <<<
