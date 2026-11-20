defmodule Checks.Ch05.Expiry do
  use Koans.Checks, review: Review.Ch05.Expiry

  alias Koans.Hidden
  alias Review.Ch05.Expiry

  @impl true
  def cases do
    [
      {:twin, "a row that expired earlier goes, and a fresh one stays",
       fn ->
         rows = [{"old", :value, 90}, {"fresh", :value, 110}]
         assert {:ok, {1, ["fresh"]}} = Hidden.isolated(fn -> sweep(rows, 100) end)
       end},
      {:exploit, "a row that expires exactly at the sweep",
       fn ->
         rows = [{"old", :value, 90}, {"edge", :value, 100}, {"fresh", :value, 110}]
         assert {:ok, {2, ["fresh"]}} = Hidden.isolated(fn -> sweep(rows, 100) end)
       end}
    ]
  end

  defp sweep(rows, now) do
    table = :ets.new(:cache, [:set, :public])
    true = :ets.insert(table, rows)
    deleted = Expiry.expire(table, now)
    {deleted, table |> :ets.tab2list() |> Enum.map(&elem(&1, 0)) |> Enum.sort()}
  end
end
