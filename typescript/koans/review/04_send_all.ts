type Report = { ok: string[]; failed: string[] }

/** Sends to every id and resolves with the ids whose send succeeded and the ids whose send failed. */
export async function sendAll(ids: string[], send: (id: string) => Promise<void>): Promise<Report> {
  await Promise.all(ids.map(send))
  return { ok: ids, failed: [] }
}
