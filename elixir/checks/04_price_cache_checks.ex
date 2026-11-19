defmodule Checks.Ch04.PriceCache do
  use Koans.Checks, review: Review.Ch04.PriceCache

  alias Koans.Hidden
  alias Review.Ch04.PriceCache

  @impl true
  def cases do
    [
      {:twin, "prices load while the store is up",
       fn -> assert {:ok, {{:ok, 3}, :error}} = Hidden.isolated(&lookups_with_store_up/0) end},
      {:exploit, "the tree starts while the store is down",
       fn -> assert {:ok, :ok} = Hidden.isolated(&start_with_store_down/0) end},
      {:exploit, "a cache whose store is down answers that prices are unavailable",
       fn -> assert {:ok, {:error, :unavailable}} = Hidden.isolated(&lookup_with_store_down/0) end}
    ]
  end

  defp lookups_with_store_up do
    cache = cache_in_tree(fn -> {:ok, [{"tea", 3}]} end)
    {PriceCache.get(cache, "tea"), PriceCache.get(cache, "coffee")}
  end

  # Trapping exits turns a failed start into an {:error, _} return instead of an exit.
  defp start_with_store_down do
    Process.flag(:trap_exit, true)
    result = start_tree(&store_down/0)
    elem(result, 0)
  end

  defp lookup_with_store_down do
    Process.flag(:trap_exit, true)
    cache = cache_in_tree(&store_down/0)
    PriceCache.get(cache, "tea")
  end

  defp cache_in_tree(load) do
    {:ok, tree} = start_tree(load)
    [{_id, cache, _type, _modules}] = Supervisor.which_children(tree)
    cache
  end

  defp start_tree(load), do: Supervisor.start_link([{PriceCache, load}], strategy: :one_for_one)

  defp store_down, do: {:error, :econnrefused}
end
