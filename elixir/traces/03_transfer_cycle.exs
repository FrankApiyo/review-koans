defmodule Account do
  use GenServer

  def start(name, balance), do: GenServer.start(__MODULE__, {name, balance}, name: name)
  def transfer(from, to, amount), do: GenServer.cast(from, {:transfer, to, amount})

  @impl true
  def init(account), do: {:ok, account}

  @impl true
  def handle_cast({:transfer, to, amount}, {name, balance}) do
    :ok = GenServer.call(to, {:deposit, name, amount}, 300)
    {:noreply, {name, balance - amount}}
  end

  @impl true
  def handle_call({:deposit, payer, amount}, _from, {name, balance}) do
    _payer_balance = GenServer.call(payer, :balance, :infinity)
    {:reply, :ok, {name, balance + amount}}
  end

  def handle_call(:balance, _from, {_name, balance} = account), do: {:reply, balance, account}
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

# Only the first call has a timeout, so the two servers always stop in the same order.
{:ok, alice} = Account.start(:alice, 100)
{:ok, bob} = Account.start(:bob, 0)
refs = [Process.monitor(alice), Process.monitor(bob)]
:ok = Account.transfer(:alice, :bob, 10)

for ref <- refs do
  receive do
    {:DOWN, ^ref, :process, _account, _reason} -> :ok
  end

  receive do
    :printed -> :ok
  end
end
