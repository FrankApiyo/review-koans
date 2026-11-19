defmodule Checks.Ch02.Notifier do
  use Koans.Checks, review: Review.Ch02.Notifier

  alias Koans.Hidden
  alias Review.Ch02.Notifier

  @good ["a@x.io", "b@x.io"]
  @with_bad ["a@x.io", "bad@", "b@x.io"]

  @impl true
  def cases do
    [
      {:twin, "every good address is delivered",
       fn ->
         assert {:ok, {_, _, ["a@x.io", "b@x.io"]}} = Hidden.isolated(fn -> deliver(@good) end)
       end},
      {:exploit, "a delivery that crashes cannot take the caller with it",
       fn ->
         assert {:ok, {[], _, ["a@x.io", "b@x.io"]}} =
                  Hidden.isolated(fn -> deliver(@with_bad) end)
       end},
      {:exploit, "the caller holds no monitor it never reads",
       fn -> assert {:ok, {_, [], _}} = Hidden.isolated(fn -> deliver(@with_bad) end) end}
    ]
  end

  # Each delivery waits for :go, so the caller's links and monitors are read while every
  # delivery is still alive. Each is then released and awaited through its own :DOWN.
  defp deliver(addrs) do
    test = self()
    :ok = Notifier.deliver_all(addrs, gated(test))
    workers = Enum.map(addrs, fn _ -> ready() end)
    {:links, links} = Process.info(self(), :links)
    {:monitors, monitors} = Process.info(self(), :monitors)
    linked = for {_addr, worker} <- workers, worker in links, do: worker
    Enum.each(workers, fn {_addr, worker} -> release(worker) end)
    {linked, monitors, delivered(addrs)}
  end

  defp gated(test) do
    fn addr ->
      send(test, {:ready, addr, self()})

      receive do
        :go -> :ok
      end

      if String.ends_with?(addr, "@"), do: raise(ArgumentError, "no domain")
      send(test, {:delivered, addr})
    end
  end

  defp ready do
    receive do
      {:ready, addr, worker} -> {addr, worker}
    end
  end

  defp release(worker) do
    ref = Process.monitor(worker)
    send(worker, :go)

    receive do
      {:DOWN, ^ref, :process, ^worker, _reason} -> :ok
    end
  end

  defp delivered(addrs) do
    for addr <- addrs,
        received?({:delivered, addr}),
        do: addr
  end

  defp received?(message) do
    {:messages, messages} = Process.info(self(), :messages)
    message in messages
  end
end
