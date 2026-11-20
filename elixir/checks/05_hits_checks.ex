defmodule Checks.Ch05.Hits do
  use Koans.Checks, review: Review.Ch05.Hits

  alias Checks.Ch05.EtsCalls
  alias Koans.Hidden
  alias Review.Ch05.Hits

  @impl true
  def cases do
    [
      {:twin, "a path nobody visited counts zero",
       fn -> assert {:ok, 0} = Hidden.isolated(fn -> Hits.count(Hits.new(), "/") end) end},
      {:exploit, "the first hits of a path count up from one",
       fn -> assert {:ok, {[1, 2, 3], 3}} = Hidden.isolated(&three_hits/0) end},
      {:exploit, "a hit reads the count, then writes it in a separate call",
       fn -> assert {:ok, {1, :one_update}} = Hidden.isolated(&traced_hit/0) end},
      {:exploit, "many request processes hit one path at once",
       fn -> assert {:ok, 5000} = Hidden.isolated(&many_requests/0) end}
    ]
  end

  defp three_hits do
    table = Hits.new()
    {Enum.map(1..3, fn _hit -> Hits.hit(table, "/") end), Hits.count(table, "/")}
  end

  # Another request can hit between two table calls; counting the calls catches that without
  # racing anything.
  defp traced_hit do
    table = Hits.new()
    {count, calls} = EtsCalls.during(fn -> Hits.hit(table, "/") end)

    {count,
     if(EtsCalls.write_after_read?(calls, insert: 2), do: :read_then_write, else: :one_update)}
  end

  # Every hit is one atomic table call, so the total is the same whatever the interleaving.
  defp many_requests do
    table = Hits.new()

    1..50
    |> Enum.map(fn _request ->
      Task.async(fn -> Enum.each(1..100, fn _hit -> Hits.hit(table, "/pricing") end) end)
    end)
    |> Task.await_many()

    Hits.count(table, "/pricing")
  end
end
