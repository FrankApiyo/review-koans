/** Whether `user` may edit `doc`: only a signed-in user whose id is the document's owner id. `user` is undefined when no one is signed in, and a guest has no id. */
export const canEdit = (user: { id?: string } | undefined, doc: { ownerId?: string }): boolean =>
  doc.ownerId === user?.id
