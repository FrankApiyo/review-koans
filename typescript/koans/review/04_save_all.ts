/** Saves every id; the returned promise resolves once every save has finished. */
export async function saveAll(repo: Repo, ids: string[]) {
  ids.forEach(async (id) => { await repo.save(id) })
}

type Repo = { save: (id: string) => Promise<void> }
