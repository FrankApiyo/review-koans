defmodule Checks.Ch04.Warmup do
  use Koans.Checks, review: Review.Ch04.Warmup

  alias Koans.Hidden
  alias Review.Ch04.Warmup

  @impl true
  def cases do
    [
      {:twin, "the job runs when the tree starts",
       fn -> assert {:ok, :ran} = Hidden.isolated(&first_run/0) end},
      {:exploit, "a job that crashes once runs again, then stays stopped",
       fn -> assert {:ok, {true, 2}} = Hidden.isolated(&runs_after_one_crash/0) end}
    ]
  end

  # Trapping exits keeps this process alive if the tree gives up.
  defp first_run do
    Process.flag(:trap_exit, true)
    test = self()
    {:ok, _tree} = start_tree(fn -> send(test, :ran) end)

    receive do
      :ran -> :ran
    end
  end

  defp runs_after_one_crash do
    Process.flag(:trap_exit, true)
    runs = :counters.new(1, [])

    {:ok, tree} =
      start_tree(fn ->
        :counters.add(runs, 1, 1)
        if :counters.get(runs, 1) < 2, do: raise("cold cache")
      end)

    true = Hidden.wait_until(fn -> settled?(tree) end)
    {Process.alive?(tree), :counters.get(runs, 1)}
  end

  defp start_tree(work), do: Supervisor.start_link([{Warmup, work}], strategy: :one_for_one)

  defp settled?(tree) do
    case Supervisor.which_children(tree) do
      [] -> true
      [{_id, :undefined, _type, _modules}] -> true
      _running -> false
    end
  catch
    :exit, _reason -> true
  end
end
