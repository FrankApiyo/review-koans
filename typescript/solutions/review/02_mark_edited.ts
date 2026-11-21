type Draft = { title: string; meta: { tags: string[]; due: Date } }

/** A copy of the draft with "edited" added to its tags; the draft itself is left as it was. */
export const markEdited = (d: Draft): Draft => {
  const next = structuredClone(d)
  next.meta.tags.push("edited")
  return next
}
