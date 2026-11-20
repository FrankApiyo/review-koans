defmodule SessionStore do
  use GenServer

  def start, do: GenServer.start(__MODULE__, :ok, name: __MODULE__)
  def reload, do: GenServer.cast(__MODULE__, :reload)

  def fetch(id) do
    case :ets.lookup(:sessions, id) do
      [{^id, user}] -> {:ok, user}
      [] -> :error
    end
  end

  @impl true
  def init(:ok), do: {:ok, :ets.new(:sessions, [:named_table, :public])}

  @impl true
  def handle_cast(:reload, _table), do: raise("session reload failed")
end

defmodule Auth do
  def current_user(session_id) do
    {:ok, user} = SessionStore.fetch(session_id)
    user
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

# A table goes when its owner dies, but not necessarily before the owner's :DOWN arrives.
defmodule Gone do
  def wait(table) do
    if :ets.whereis(table) == :undefined do
      :ok
    else
      :erlang.yield()
      wait(table)
    end
  end
end

{:ok, default} = :logger.get_handler_config(:default)
:ok = :logger.remove_handler(:default)

:ok =
  :logger.add_handler(:printed, Printed, %{
    formatter: default.formatter,
    config: %{script: self()}
  })

{:ok, store} = SessionStore.start()
true = :ets.insert(:sessions, {"s1", "ada"})
ref = Process.monitor(store)
:ok = SessionStore.reload()

receive do
  {:DOWN, ^ref, :process, ^store, _reason} -> :ok
end

receive do
  :printed -> :ok
end

:ok = Gone.wait(:sessions)
{request, ref} = spawn_monitor(Auth, :current_user, ["s1"])

receive do
  {:DOWN, ^ref, :process, ^request, _reason} -> :ok
end

receive do
  :printed -> :ok
end
