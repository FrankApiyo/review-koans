defmodule Checks.Ch05.Expiry do
  use Koans.Checks, review: Review.Ch05.Expiry

  alias Checks.Ch05.EtsCalls
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
       end},
      {:exploit, "a sweep reads the expired rows, then deletes them by key in separate calls",
       fn -> assert {:ok, {1, :one_sweep}} = Hidden.isolated(&traced_sweep/0) end}
    ]
  end

  defp sweep(rows, now) do
    table = :ets.new(:cache, [:set, :public])
    true = :ets.insert(table, rows)
    deleted = Expiry.expire(table, now)
    {deleted, table |> :ets.tab2list() |> Enum.map(&elem(&1, 0)) |> Enum.sort()}
  end

  # A row refreshed between reading it and deleting it by key is deleted although it is live.
  # Deleting the exact object that was read (delete_object/2) keeps a refreshed row.
  defp traced_sweep do
    table = :ets.new(:cache, [:set, :public])
    true = :ets.insert(table, [{"old", :value, 90}, {"fresh", :value, 110}])
    {deleted, calls} = EtsCalls.during(fn -> Expiry.expire(table, 100) end)
    {deleted, sweep_shape(calls)}
  end

  defp sweep_shape(calls) do
    if EtsCalls.write_after_read?(calls, delete: 2, match_delete: 2),
      do: :delete_by_key_after_read,
      else: :one_sweep
  end
end
