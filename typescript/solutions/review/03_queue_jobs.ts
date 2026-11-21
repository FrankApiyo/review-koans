/** One queue entry per job, in order; calling an entry runs its own job, and no job runs before that. */
export function queueJobs(jobs: string[], run: (job: string) => void): Array<() => void> {
  const queue: Array<() => void> = []
  for (let i = 0; i < jobs.length; i++) queue.push(() => run(jobs[i]))
  return queue
}
