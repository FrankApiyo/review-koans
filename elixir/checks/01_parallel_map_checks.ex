defmodule Checks.Ch01.ParallelMap do
  use Koans.Checks, review: Review.Ch01.ParallelMap

  alias Koans.Hidden
  alias Review.Ch01.ParallelMap

  @impl true
  def cases do
    [
      {:twin, "an empty list",
       fn -> assert {:ok, []} = Hidden.isolated(fn -> ParallelMap.map([], & &1) end) end},
      {:exploit, "one item comes back",
       fn -> assert {:ok, [42]} = Hidden.isolated(fn -> ParallelMap.map([21], &(&1 * 2)) end) end},
      {:exploit, "results keep input order when they finish in reverse",
       fn -> assert {:ok, [2, 4, 6]} = Hidden.isolated(&map_finishing_in_reverse/0) end}
    ]
  end

  # Each worker waits for :go. Receive tracing on the caller shows when a result has reached
  # it, whatever the reply's shape, so the next worker is released only after that.
  defp map_finishing_in_reverse do
    test = self()

    gated = fn x ->
      send(test, {:ready, x, self()})

      receive do
        :go -> x * 2
      end
    end

    caller =
      spawn_link(fn -> send(test, {:mapped, self(), ParallelMap.map([1, 2, 3], gated)}) end)

    workers = Map.new(1..3, fn _ -> ready() end)
    :erlang.trace(caller, true, [:receive])
    Enum.each([3, 2, 1], &release(caller, Map.fetch!(workers, &1), &1 * 2))

    receive do
      {:mapped, ^caller, results} -> results
    end
  end

  defp ready do
    receive do
      {:ready, x, worker} -> {x, worker}
    end
  end

  defp release(caller, worker, expected) do
    send(worker, :go)

    receive do
      {:trace, ^caller, :receive, {_tag, ^expected}} -> :ok
    end
  end
end
