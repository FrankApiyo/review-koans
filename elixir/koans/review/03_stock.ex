defmodule Review.Ch03.Stock do
  @moduledoc """
  A server holds how many units of one item are left. `reserve/2` takes `k` units and returns
  `:ok`, or `{:error, :out_of_stock}` when fewer than `k` are left.
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
  def handle_call({:set, units}, _from, _old), do: {:reply, :ok, units}

  @spec reserve(GenServer.server(), pos_integer()) :: :ok | {:error, :out_of_stock}
  def reserve(stock, k) do
    units = GenServer.call(stock, :available)

    if units >= k do
      GenServer.call(stock, {:set, units - k})
    else
      {:error, :out_of_stock}
    end
  end
end
