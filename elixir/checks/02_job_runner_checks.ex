defmodule Checks.Ch02.JobRunner do
  use Koans.Checks, review: Review.Ch02.JobRunner

  alias Koans.Hidden
  alias Review.Ch02.JobRunner

  @impl true
  def cases do
    [
      {:twin, "a job that fails is recorded",
       fn ->
         assert {:ok, %{failed: [:boom]}} =
                  Hidden.isolated(fn -> stats_once(fn -> exit(:boom) end, &failed?/1) end)
       end},
      {:exploit, "a job that finishes is counted, and the server keeps running",
       fn ->
         assert {:ok, %{done: 1, failed: []}} =
                  Hidden.isolated(fn -> stats_once(fn -> :finished end, &finished?/1) end)
       end}
    ]
  end

  # The server learns of a job's end from an exit signal the checks cannot order against
  # their own call, so they poll stats/1 until the outcome shows.
  defp stats_once(job, settled?) do
    {:ok, server} = JobRunner.start_link()
    :ok = JobRunner.run(server, job)
    true = Hidden.wait_until(fn -> settled?.(JobRunner.stats(server)) end)
    JobRunner.stats(server)
  end

  defp failed?(%{failed: [_ | _]}), do: true
  defp failed?(_stats), do: false

  defp finished?(%{done: done}) when done > 0, do: true
  defp finished?(_stats), do: false
end
