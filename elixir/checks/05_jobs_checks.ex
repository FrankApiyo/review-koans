defmodule Checks.Ch05.Jobs do
  use Koans.Checks, review: Review.Ch05.Jobs

  alias Checks.Ch05.EtsCalls
  alias Koans.Hidden
  alias Review.Ch05.Jobs

  @impl true
  def cases do
    [
      {:twin, "the first claim of each job succeeds",
       fn -> assert {:ok, {:ok, :ok, :a, :b}} = Hidden.isolated(&first_claims/0) end},
      {:exploit, "a second worker claims a job that is already claimed",
       fn -> assert {:ok, {{:error, :taken}, :a}} = Hidden.isolated(&second_claim/0) end},
      {:exploit, "a claim reads the table before the call that claims the job",
       fn -> assert {:ok, {:ok, :one_decision}} = Hidden.isolated(&traced_claim/0) end}
    ]
  end

  defp first_claims do
    table = Jobs.new()

    {Jobs.claim(table, 1, :a), Jobs.claim(table, 2, :b), Jobs.owner(table, 1),
     Jobs.owner(table, 2)}
  end

  defp second_claim do
    table = Jobs.new()
    :ok = Jobs.claim(table, 1, :a)
    {Jobs.claim(table, 1, :b), Jobs.owner(table, 1)}
  end

  # Another worker can run between two table calls, so a claim must not rest on an earlier
  # read: the call that writes decides alone. The calls are counted, not raced, so every run
  # gives the same answer.
  defp traced_claim do
    table = Jobs.new()
    {result, calls} = EtsCalls.during(fn -> Jobs.claim(table, 3, :c) end)
    {result, decision(calls)}
  end

  defp decision(calls) do
    if EtsCalls.write_after_read?(calls, insert: 2, insert_new: 2),
      do: :read_then_write,
      else: :one_decision
  end
end
