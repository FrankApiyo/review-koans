defmodule Course.Ch04.Store do
  @moduledoc "Holds the catalog rows, `{sku, price}` pairs, that it is started with."

  use Agent

  @spec start_link([{String.t(), non_neg_integer()}]) :: Agent.on_start()
  def start_link(rows), do: Agent.start_link(fn -> rows end, name: __MODULE__)

  @spec all() :: [{String.t(), non_neg_integer()}]
  def all, do: Agent.get(__MODULE__, & &1)
end

defmodule Course.Ch04.Cache do
  @moduledoc """
  Serves price lookups from a copy of `Course.Ch04.Store`'s rows, read once when it starts.
  `get/1` returns the price, or `nil` for an unknown sku.
  """

  use GenServer

  alias Course.Ch04.Store

  @spec start_link(term()) :: GenServer.on_start()
  def start_link(_arg), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @spec get(String.t()) :: non_neg_integer() | nil
  def get(sku), do: GenServer.call(__MODULE__, {:get, sku})

  @impl true
  def init(:ok), do: {:ok, Map.new(Store.all())}

  @impl true
  def handle_call({:get, sku}, _from, prices), do: {:reply, Map.get(prices, sku), prices}
end
