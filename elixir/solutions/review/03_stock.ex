defmodule Review.Ch03.Stock do
  @moduledoc """
  A server holds how many units of one item are left. `reserve/2` takes `k` units and returns
  `:ok`, or `{:error, :out_of_stock}` when fewer than `k` are left. During a sale, many
  customers reserve the same item at once.
  """

  use GenServer

  @spec start_link(non_neg_integer()) :: GenServer.on_start()
  def start_link(units), do: GenServer.start_link(__MODULE__, units)

  @spec available(GenServer.server()) :: integer()
  def available(stock), do: GenServer.call(stock, :available)

  @impl true
  def init(units), do: {:ok, units}

  @impl true
  def handle_call(:available, _from, units), do: {:reply, units, units}
  def handle_call({:reserve, k}, _from, units) when units >= k, do: {:reply, :ok, units - k}
  def handle_call({:reserve, _k}, _from, units), do: {:reply, {:error, :out_of_stock}, units}

  @spec reserve(GenServer.server(), pos_integer()) :: :ok | {:error, :out_of_stock}
  def reserve(stock, k), do: GenServer.call(stock, {:reserve, k})
end
