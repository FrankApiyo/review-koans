/** Saves every id; the returned promise resolves once every save has finished. */
export async function saveAll(repo: Repo, ids: string[]) {
  // >>> fix
  ids.forEach(async (id) => { await repo.save(id) })
  // === fixed
  for (const id of ids) await repo.save(id)
  // === alt: starts every save at once and waits for all of them
  await Promise.all(ids.map((id) => repo.save(id)))
  // === alt: returns the promise that waits for every save
  return Promise.all(ids.map((id) => repo.save(id)))
  // === wrong: refuses — saves nothing and fails every call
  throw new Error("not saved")
  // === wrong: partial — awaits the array of promises, which waits for none of them
  await ids.map(async (id) => repo.save(id))
  // === wrong: partial — builds the combined promise but neither awaits nor returns it
  Promise.all(ids.map((id) => repo.save(id)))
  // === wrong: partial — loops in order but starts each save without waiting for it
  for (const id of ids) repo.save(id)
  // <<<
}

type Repo = { save: (id: string) => Promise<void> }
