defmodule Checks.Ch03.Catalog do
  use Koans.Checks, review: Review.Ch03.Catalog

  alias Koans.Hidden
  alias Review.Ch03.Catalog

  @impl true
  def cases do
    [
      {:twin, "a known product and an unknown one",
       fn -> assert {:ok, {{:ok, 1}, :error}} = Hidden.isolated(&lookups/0) end},
      {:exploit, "start_link returns while the load is still running",
       fn -> assert {:ok, {{:ok, 1}, :error}} = Hidden.isolated(&lookups_after_slow_load/0) end}
    ]
  end

  defp lookups do
    {:ok, catalog} = Catalog.start_link(fn -> %{"a" => 1} end)
    {Catalog.lookup(catalog, "a"), Catalog.lookup(catalog, "z")}
  end

  # The load waits for :go, which is sent only after start_link has returned.
  defp lookups_after_slow_load do
    test = self()

    {:ok, catalog} =
      Catalog.start_link(fn ->
        send(test, {:loading, self()})

        receive do
          :go -> %{"a" => 1}
        end
      end)

    receive do
      {:loading, ^catalog} -> send(catalog, :go)
    end

    {Catalog.lookup(catalog, "a"), Catalog.lookup(catalog, "z")}
  end
end
