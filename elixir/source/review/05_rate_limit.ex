defmodule Review.Ch05.RateLimit do
  @moduledoc """
  Request counts per client, kept in an ETS table that a server creates; `table/1` returns
  it. Each request calls `hit/2`, which adds one for `key` and returns its count so far, and
  `count/2` reads a count without adding to it.
  """

  use GenServer

  @spec start_link(term()) :: GenServer.on_start()
  def start_link(_arg), do: GenServer.start_link(__MODULE__, :ok)

  @spec table(GenServer.server()) :: :ets.table()
  def table(limiter), do: GenServer.call(limiter, :table)

  @spec count(:ets.table(), term()) :: non_neg_integer()
  def count(table, key), do: :ets.lookup_element(table, key, 2, 0)

  # >>> fix
  @spec hit(:ets.table(), term()) :: pos_integer()
  def hit(table, key), do: :ets.update_counter(table, key, 1, {key, 0})

  @impl true
  def init(:ok), do: {:ok, :ets.new(:hits, [:set, read_concurrency: true])}

  @impl true
  def handle_call(:table, _from, table), do: {:reply, table, table}
  # === fixed
  @spec hit(:ets.table(), term()) :: pos_integer()
  def hit(table, key), do: :ets.update_counter(table, key, 1, {key, 0})

  @impl true
  def init(:ok), do: {:ok, :ets.new(:hits, [:set, :public, write_concurrency: true])}

  @impl true
  def handle_call(:table, _from, table), do: {:reply, table, table}
  # === alt: :public added, read_concurrency kept
  @spec hit(:ets.table(), term()) :: pos_integer()
  def hit(table, key), do: :ets.update_counter(table, key, 1, {key, 0})

  @impl true
  def init(:ok), do: {:ok, :ets.new(:hits, [:set, :public, read_concurrency: true])}

  @impl true
  def handle_call(:table, _from, table), do: {:reply, table, table}
  # === alt: writes routed through the server that owns the table
  @spec hit(:ets.table(), term()) :: pos_integer()
  def hit(table, key), do: GenServer.call(:ets.info(table, :owner), {:hit, key})

  @impl true
  def init(:ok), do: {:ok, :ets.new(:hits, [:set, read_concurrency: true])}

  @impl true
  def handle_call(:table, _from, table), do: {:reply, table, table}

  def handle_call({:hit, key}, _from, table),
    do: {:reply, :ets.update_counter(table, key, 1, {key, 0}), table}
  # === wrong: refuses — a :private table, which no other process can read or write
  @spec hit(:ets.table(), term()) :: pos_integer()
  def hit(table, key), do: :ets.update_counter(table, key, 1, {key, 0})

  @impl true
  def init(:ok), do: {:ok, :ets.new(:hits, [:set, :private])}

  @impl true
  def handle_call(:table, _from, table), do: {:reply, table, table}
  # === wrong: partial — write_concurrency added, but the table is still :protected
  @spec hit(:ets.table(), term()) :: pos_integer()
  def hit(table, key), do: :ets.update_counter(table, key, 1, {key, 0})

  @impl true
  def init(:ok),
    do: {:ok, :ets.new(:hits, [:set, read_concurrency: true, write_concurrency: true])}

  @impl true
  def handle_call(:table, _from, table), do: {:reply, table, table}
  # <<<
end
