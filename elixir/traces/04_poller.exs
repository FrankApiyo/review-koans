defmodule Feed do
  def fetch, do: {:error, :timeout}
end

defmodule Poller do
  use GenServer

  def start_link(feed), do: GenServer.start_link(__MODULE__, feed, name: __MODULE__)

  @impl true
  def init(feed), do: {:ok, %{feed: feed}, {:continue, :first_poll}}

  @impl true
  def handle_continue(:first_poll, state) do
    {:ok, body} = state.feed.fetch()
    {:noreply, Map.put(state, :body, body)}
  end
end

# The logger can print a report after the script has exited. This handler prints each report
# as the default handler would, then tells the script, so every run prints the same output.
defmodule Printed do
  def log(event, %{formatter: {formatter, options}, config: %{script: script}}) do
    IO.write(formatter.format(event, options))
    send(script, :printed)
  end
end

{:ok, default} = :logger.get_handler_config(:default)
:ok = :logger.remove_handler(:default)

:ok =
  :logger.add_handler(:printed, Printed, %{
    formatter: default.formatter,
    config: %{script: self()}
  })

Process.flag(:trap_exit, true)
{:ok, feeds} = Supervisor.start_link([{Poller, Feed}], strategy: :one_for_one)

receive do
  {:EXIT, ^feeds, :shutdown} -> :ok
end

for _ <- 1..4 do
  receive do
    :printed -> :ok
  end
end
