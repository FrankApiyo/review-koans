defmodule Checks.Ch04.Tree do
  use Koans.Checks, review: Review.Ch04.Tree

  alias Course.Ch04.{Cache, Store}
  alias Koans.Hidden
  alias Review.Ch04.Tree

  @impl true
  def cases do
    [
      {:twin, "the tree supervises one store and one cache",
       fn -> assert {:ok, [Cache, Store]} = Hidden.isolated(&supervised_modules/0) end},
      {:exploit, "the tree starts, and the cache holds the store's rows",
       fn -> assert {:ok, {3, nil}} = Hidden.isolated(&lookups_after_start/0) end}
    ]
  end

  # Read from init/1 without starting the tree, so the start order plays no part here.
  defp supervised_modules do
    {:ok, {_flags, specs}} = Tree.init([{"tea", 3}])

    specs
    |> Enum.map(fn %{start: {module, _function, _args}} -> module end)
    |> Enum.sort()
  end

  defp lookups_after_start do
    {:ok, tree} = Tree.start_link([{"tea", 3}])
    lookups = {Cache.get("tea"), Cache.get("coffee")}
    :ok = Supervisor.stop(tree)
    lookups
  end
end
