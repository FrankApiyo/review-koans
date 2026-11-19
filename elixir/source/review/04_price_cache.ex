defmodule Review.Ch04.PriceCache do
  @moduledoc """
  Serves prices loaded from the price store by `load`, which returns `{:ok, rows}` or
  `{:error, reason}`. It runs under the app's supervision tree. `get/2` returns
  `{:ok, price}`, `:error` for an unknown sku, or `{:error, :unavailable}` while the store
  cannot be read.
  """

  use GenServer

  @spec start_link((-> {:ok, [{String.t(), non_neg_integer()}]} | {:error, term()})) ::
          GenServer.on_start()
  def start_link(load), do: GenServer.start_link(__MODULE__, load)

  @spec get(GenServer.server(), String.t()) ::
          {:ok, non_neg_integer()} | :error | {:error, :unavailable}
  def get(cache, sku), do: GenServer.call(cache, {:get, sku})

  @impl true
  # >>> fix
  def init(load) do
    {:ok, rows} = load.()
    {:ok, Map.new(rows)}
  end

  @impl true
  def handle_call({:get, sku}, _from, prices), do: {:reply, Map.fetch(prices, sku), prices}
  # === fixed
  def init(load), do: {:ok, :loading, {:continue, {:load, load}}}

  @impl true
  def handle_continue({:load, load}, :loading) do
    case load.() do
      {:ok, rows} -> {:noreply, Map.new(rows)}
      {:error, _reason} -> {:noreply, :unavailable}
    end
  end

  @impl true
  def handle_call({:get, _sku}, _from, :unavailable),
    do: {:reply, {:error, :unavailable}, :unavailable}

  def handle_call({:get, sku}, _from, prices), do: {:reply, Map.fetch(prices, sku), prices}
  # === alt: the loader kept as the state until handle_continue runs it
  def init(load), do: {:ok, load, {:continue, :load}}

  @impl true
  def handle_continue(:load, load) do
    case load.() do
      {:ok, rows} -> {:noreply, {:ready, Map.new(rows)}}
      {:error, _reason} -> {:noreply, :unavailable}
    end
  end

  @impl true
  def handle_call({:get, sku}, _from, {:ready, prices} = state),
    do: {:reply, Map.fetch(prices, sku), state}

  def handle_call({:get, _sku}, _from, :unavailable),
    do: {:reply, {:error, :unavailable}, :unavailable}
  # === alt: the load's error handled in init
  def init(load) do
    case load.() do
      {:ok, rows} -> {:ok, Map.new(rows)}
      {:error, _reason} -> {:ok, :unavailable}
    end
  end

  @impl true
  def handle_call({:get, _sku}, _from, :unavailable),
    do: {:reply, {:error, :unavailable}, :unavailable}

  def handle_call({:get, sku}, _from, prices), do: {:reply, Map.fetch(prices, sku), prices}
  # === wrong: refuses — never loads, so every price is unavailable
  def init(_load), do: {:ok, :unavailable}

  @impl true
  def handle_call({:get, _sku}, _from, state), do: {:reply, {:error, :unavailable}, state}
  # === wrong: partial — the same match moved into handle_continue
  def init(load), do: {:ok, %{}, {:continue, {:load, load}}}

  @impl true
  def handle_continue({:load, load}, _prices) do
    {:ok, rows} = load.()
    {:noreply, Map.new(rows)}
  end

  @impl true
  def handle_call({:get, sku}, _from, prices), do: {:reply, Map.fetch(prices, sku), prices}
  # === wrong: partial — treats a store that is down as an empty catalog
  def init(load), do: {:ok, %{}, {:continue, {:load, load}}}

  @impl true
  def handle_continue({:load, load}, _prices) do
    case load.() do
      {:ok, rows} -> {:noreply, Map.new(rows)}
      {:error, _reason} -> {:noreply, %{}}
    end
  end

  @impl true
  def handle_call({:get, sku}, _from, prices), do: {:reply, Map.fetch(prices, sku), prices}
  # <<<
end
