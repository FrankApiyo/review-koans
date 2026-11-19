defmodule Cart do
  use GenServer

  @limit 100

  def start, do: GenServer.start(__MODULE__, [], name: __MODULE__)
  def add(price), do: GenServer.cast(__MODULE__, {:add, price})
  def total, do: GenServer.call(__MODULE__, :total)

  @impl true
  def init(prices), do: {:ok, prices}

  @impl true
  def handle_cast({:add, price}, prices) do
    if total() + price <= @limit, do: {:noreply, [price | prices]}, else: {:noreply, prices}
  end

  @impl true
  def handle_call(:total, _from, prices), do: {:reply, Enum.sum(prices), prices}
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

{:ok, cart} = Cart.start()
ref = Process.monitor(cart)
:ok = Cart.add(3)

receive do
  {:DOWN, ^ref, :process, ^cart, _reason} -> :ok
end

receive do
  :printed -> :ok
end
