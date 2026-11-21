type Draft = { title: string; meta: { tags: string[]; due: Date } }

/** A copy of the draft with "edited" added to its tags; the draft itself is left as it was. */
// >>> guard
export const markEdited = (d: Draft): Draft => {
  const next = structuredClone(d)
  next.meta.tags.push("edited")
  return next
}
// === wrong: partial — copies one level into meta, so the copy shares the draft's tags
export const markEdited = (d: Draft): Draft => {
  const next = { ...d, meta: { ...d.meta } }
  next.meta.tags.push("edited")
  return next
}
// === wrong: partial — copies through JSON, so the due date comes back as text
export const markEdited = (d: Draft): Draft => {
  const next = JSON.parse(JSON.stringify(d))
  next.meta.tags.push("edited")
  return next
}
// <<<
