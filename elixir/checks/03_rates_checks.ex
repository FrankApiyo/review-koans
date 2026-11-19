defmodule Checks.Ch03.Rates do
  use Koans.Checks, review: Review.Ch03.Rates

  alias Koans.Hidden
  alias Review.Ch03.Rates

  @fresh %{"EUR" => 1.1}

  @impl true
  def cases do
    [
      {:twin, "new rates show once the fetch returns",
       fn -> assert {:ok, %{"EUR" => 1.1}} = Hidden.isolated(&rates_after_fetch/0) end},
      {:exploit, "the fetch runs outside the server",
       fn -> assert {:ok, false} = Hidden.isolated(&fetch_runs_in_server?/0) end},
      {:exploit, "the server answers while a fetch is in flight",
       fn -> assert {:ok, 0} = Hidden.isolated(&rates_during_fetch/0) end}
    ]
  end

  defp rates_after_fetch do
    {server, fetcher} = refreshing()
    send(fetcher, :release)
    true = Hidden.wait_until(fn -> map_size(Rates.get(server)) > 0 end)
    Rates.get(server)
  end

  defp fetch_runs_in_server? do
    {server, fetcher} = refreshing()
    send(fetcher, :release)
    fetcher in [server]
  end

  # The fetch holds until :release, so the server is asked while the fetch is still running.
  defp rates_during_fetch do
    {server, fetcher} = refreshing()
    during = Rates.get(server)
    send(fetcher, :release)
    map_size(during)
  end

  defp refreshing do
    test = self()
    {:ok, server} = Rates.start_link(gated_fetch(test))
    :ok = Rates.refresh(server)

    receive do
      {:fetching, fetcher} -> {server, fetcher}
    end
  end

  defp gated_fetch(test) do
    fn ->
      send(test, {:fetching, self()})

      receive do
        :release -> @fresh
      end
    end
  end
end
