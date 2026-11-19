defmodule Review.Ch03.Catalog do
  @moduledoc """
  Serves product lookups from a catalog that `load` reads when the server starts, which can
  take a while. `start_link/1` returns without waiting for the load, so a slow catalog does
  not hold up whoever starts it; `lookup/2` returns `{:ok, price}` or `:error`.
  """

  use GenServer

  @spec start_link((-> %{String.t() => non_neg_integer()})) :: GenServer.on_start()
  def start_link(load), do: GenServer.start_link(__MODULE__, load)

  @spec lookup(GenServer.server(), String.t()) :: {:ok, non_neg_integer()} | :error
  def lookup(catalog, sku), do: GenServer.call(catalog, {:lookup, sku})

  @impl true
  def init(load), do: {:ok, %{load: load, items: nil}, {:continue, :load}}

  @impl true
  def handle_continue(:load, state), do: {:noreply, %{state | items: state.load.()}}

  @impl true
  def handle_call({:lookup, sku}, _from, state), do: {:reply, Map.fetch(state.items, sku), state}
end
