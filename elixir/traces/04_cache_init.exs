defmodule Cache do
  use GenServer

  def start_link(load_all), do: GenServer.start_link(__MODULE__, load_all, name: __MODULE__)

  @impl true
  def init(load_all) do
    {:ok, rows} = load_all.()
    {:ok, Map.new(rows)}
  end
end

defmodule App.Supervisor do
  use Supervisor

  def start_link(load_all), do: Supervisor.start_link(__MODULE__, load_all, name: __MODULE__)

  @impl true
  def init(load_all), do: Supervisor.init([{Cache, load_all}], strategy: :one_for_one)
end

# The store is down. Trapping exits lets the script print the reason start_link returns, then
# the same reason as a boot log formats it. Runtime frames carry OTP's own line numbers, which
# change between patch releases, so the script keeps only its own frames.
store_down = fn -> {:error, :econnrefused} end
Process.flag(:trap_exit, true)

{:error, {:shutdown, {:failed_to_start_child, child, {error, stack}}}} =
  App.Supervisor.start_link(store_down)

own =
  Enum.filter(stack, fn {_m, _f, _a, at} -> String.starts_with?("#{at[:file]}", "traces/") end)

reason = {:shutdown, {:failed_to_start_child, child, {error, own}}}
IO.inspect(reason, label: "start_link returned {:error, reason}, where reason is")
IO.puts("\nFormatted:\n" <> Exception.format_exit(reason))
