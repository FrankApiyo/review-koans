defmodule Counter do
  use GenServer

  def start(n), do: GenServer.start(__MODULE__, n, name: __MODULE__)
  def incr, do: GenServer.call(__MODULE__, :incr)

  @impl true
  def init(n), do: {:ok, n}

  @impl true
  def handle_call(:incr, _from, n), do: {:ok, n + 1}
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

{:ok, counter} = Counter.start(0)
ref = Process.monitor(counter)

try do
  Counter.incr()
catch
  :exit, _reason -> :ok
end

receive do
  {:DOWN, ^ref, :process, ^counter, _reason} -> :ok
end

receive do
  :printed -> :ok
end
