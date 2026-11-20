defmodule Review.Ch05.Flags do
  @moduledoc """
  Feature flags. Any process reads a flag straight from an ETS table with `get/1`, which
  returns its value, or `nil` for a flag nobody set. Changes go through one server, which the
  app's supervisor starts: `put/2` sets a flag and returns `:ok`.
  """

  use GenServer

  @spec start_link(term()) :: GenServer.on_start()
  def start_link(_arg), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @spec put(atom(), term()) :: :ok
  def put(flag, value), do: GenServer.call(__MODULE__, {:put, flag, value})

  @spec get(atom()) :: term()
  def get(flag) do
    case :ets.lookup(table(), flag) do
      [{^flag, value}] -> value
      [] -> nil
    end
  end

  @impl true
  def handle_call({:put, flag, value}, _from, state) do
    true = :ets.insert(table(), {flag, value})
    {:reply, :ok, state}
  end

  @impl true
  def init(:ok), do: {:ok, nil}

  defp table do
    case :ets.whereis(:flags) do
      :undefined -> :ets.new(:flags, [:named_table, :public, read_concurrency: true])
      _table -> :flags
    end
  end
end
