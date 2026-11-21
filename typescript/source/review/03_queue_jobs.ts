/** One queue entry per job, in order; calling an entry runs its own job, and no job runs before that. */
export function queueJobs(jobs: string[], run: (job: string) => void): Array<() => void> {
  const queue: Array<() => void> = []
  // >>> fix
  for (var i = 0; i < jobs.length; i++) queue.push(() => run(jobs[i]))
  // === fixed
  for (let i = 0; i < jobs.length; i++) queue.push(() => run(jobs[i]))
  // === alt: copies the job into a block-scoped const before queueing it
  for (var i = 0; i < jobs.length; i++) {
    const job = jobs[i]
    queue.push(() => run(job))
  }
  // === alt: maps each job to its own entry
  return jobs.map((job) => () => run(job))
  // === wrong: refuses — queues nothing
  return []
  // === wrong: partial — a var inside the loop is still one variable, so every entry runs the last job
  for (var i = 0; i < jobs.length; i++) {
    var job = jobs[i]
    queue.push(() => run(job))
  }
  // === wrong: partial — runs each job while queueing, before its entry is called
  for (var i = 0; i < jobs.length; i++) {
    run(jobs[i])
    queue.push(() => {})
  }
  // <<<
  return queue
}
