defmodule Checks.Ch03.Registry do
  use Koans.Checks, review: Review.Ch03.Registry

  alias Koans.Hidden
  alias Review.Ch03.Registry

  @impl true
  def cases do
    [
      {:twin, "a running client is counted",
       fn -> assert {:ok, 1} = Hidden.isolated(&count_while_running/0) end},
      {:twin, "a :DOWN for a process that never registered leaves running clients counted",
       fn -> assert {:ok, 1} = Hidden.isolated(&count_after_unrelated_down/0) end},
      {:exploit, "a client that ends is no longer counted",
       fn -> assert {:ok, true} = Hidden.isolated(fn -> uncounted_after?(:normal) end) end},
      {:exploit, "a client that crashes is no longer counted",
       fn -> assert {:ok, true} = Hidden.isolated(fn -> uncounted_after?(:crash) end) end}
    ]
  end

  defp count_while_running do
    {:ok, registry} = Registry.start_link()
    client = registered_client(registry)
    count = Registry.count(registry)
    Process.exit(client, :kill)
    count
  end

  defp count_after_unrelated_down do
    {:ok, registry} = Registry.start_link()
    client = registered_client(registry)
    stranger = spawn(fn -> :ok end)
    send(registry, {:DOWN, make_ref(), :process, stranger, :normal})
    count = Registry.count(registry)
    Process.exit(client, :kill)
    count
  end

  # The registry learns of the client's end from a :DOWN the checks cannot order against
  # their own call, so they poll count/1 until it shows.
  defp uncounted_after?(ending) do
    {:ok, registry} = Registry.start_link()
    client = registered_client(registry)
    send(client, {:end, ending})
    Hidden.wait_until(fn -> Registry.count(registry) < 1 end)
  end

  defp registered_client(registry) do
    test = self()

    client =
      spawn(fn ->
        :ok = Registry.register(registry)
        send(test, {:registered, self()})

        receive do
          {:end, :normal} -> :ok
          {:end, :crash} -> exit(:crash)
        end
      end)

    receive do
      {:registered, ^client} -> client
    end
  end
end
