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
  # >>> fix
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
  # === fixed
  def handle_call({:reserve, k}, _from, units) when units >= k, do: {:reply, :ok, units - k}
  def handle_call({:reserve, _k}, _from, units), do: {:reply, {:error, :out_of_stock}, units}

  @spec reserve(GenServer.server(), pos_integer()) :: :ok | {:error, :out_of_stock}
  def reserve(stock, k), do: GenServer.call(stock, {:reserve, k})
  # === alt: one clause that decides with if, inside the server
  def handle_call({:reserve, k}, _from, units) do
    if units >= k do
      {:reply, :ok, units - k}
    else
      {:reply, {:error, :out_of_stock}, units}
    end
  end

  @spec reserve(GenServer.server(), pos_integer()) :: :ok | {:error, :out_of_stock}
  def reserve(stock, k), do: GenServer.call(stock, {:reserve, k})
  # === alt: the caller may still check first, as long as the server decides again
  def handle_call({:reserve, k}, _from, units) when units >= k, do: {:reply, :ok, units - k}
  def handle_call({:reserve, _k}, _from, units), do: {:reply, {:error, :out_of_stock}, units}

  @spec reserve(GenServer.server(), pos_integer()) :: :ok | {:error, :out_of_stock}
  def reserve(stock, k) do
    if GenServer.call(stock, :available) >= k do
      GenServer.call(stock, {:reserve, k})
    else
      {:error, :out_of_stock}
    end
  end
  # === wrong: refuses — reports every item as sold out
  def handle_call({:set, units}, _from, _old), do: {:reply, :ok, units}

  @spec reserve(GenServer.server(), pos_integer()) :: :ok | {:error, :out_of_stock}
  def reserve(stock, k) do
    _ = {stock, k}
    {:error, :out_of_stock}
  end
  # === wrong: partial — checks first, then takes without checking again in the server
  def handle_call({:take, k}, _from, units), do: {:reply, :ok, units - k}

  @spec reserve(GenServer.server(), pos_integer()) :: :ok | {:error, :out_of_stock}
  def reserve(stock, k) do
    if GenServer.call(stock, :available) >= k do
      GenServer.call(stock, {:take, k})
    else
      {:error, :out_of_stock}
    end
  end
  # === wrong: partial — the server refuses a negative count, but two stale reads both set the same count
  def handle_call({:set, units}, _from, _old) when units >= 0, do: {:reply, :ok, units}
  def handle_call({:set, _units}, _from, old), do: {:reply, {:error, :out_of_stock}, old}

  @spec reserve(GenServer.server(), pos_integer()) :: :ok | {:error, :out_of_stock}
  def reserve(stock, k) do
    units = GenServer.call(stock, :available)
    GenServer.call(stock, {:set, units - k})
  end
  # <<<
end
