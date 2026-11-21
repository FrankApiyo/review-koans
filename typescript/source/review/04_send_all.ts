type Report = { ok: string[]; failed: string[] }

/** Sends to every id and resolves with the ids whose send succeeded and the ids whose send failed. */
export async function sendAll(ids: string[], send: (id: string) => Promise<void>): Promise<Report> {
  // >>> fix
  await Promise.all(ids.map(send))
  return { ok: ids, failed: [] }
  // === fixed
  const results = await Promise.allSettled(ids.map(send))
  return {
    ok: ids.filter((_, i) => results[i].status === "fulfilled"),
    failed: ids.filter((_, i) => results[i].status === "rejected"),
  }
  // === alt: sends one at a time and sorts each id by whether its send threw
  const report: Report = { ok: [], failed: [] }
  for (const id of ids) {
    try {
      await send(id)
      report.ok.push(id)
    } catch {
      report.failed.push(id)
    }
  }
  return report
  // === wrong: refuses — reports every id as failed
  return { ok: [], failed: ids }
  // === wrong: partial — swallows each failure, so a failed send is reported as ok
  await Promise.all(ids.map((id) => send(id).catch(() => null)))
  return { ok: ids, failed: [] }
  // === wrong: partial — one failure makes the whole batch count as failed
  try {
    await Promise.all(ids.map(send))
    return { ok: ids, failed: [] }
  } catch {
    return { ok: [], failed: ids }
  }
  // === wrong: partial — records each failure but still reports every id as ok
  const failed: string[] = []
  await Promise.all(ids.map((id) => send(id).catch(() => failed.push(id))))
  return { ok: ids, failed }
  // <<<
}
