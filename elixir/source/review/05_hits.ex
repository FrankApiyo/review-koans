defmodule Review.Ch05.Hits do
  @moduledoc """
  Counts page hits. Request processes share one table: `hit/2` adds one hit to `path` and
  returns its count so far, and `count/2` returns a path's count, 0 for a path nobody visited.
  """

  # >>> guard
  @spec new() :: :ets.table()
  def new, do: :ets.new(:hits, [:set, :public, write_concurrency: true])

  @spec hit(:ets.table(), String.t()) :: pos_integer()
  def hit(table, path), do: :ets.update_counter(table, path, {2, 1}, {path, 0})
  # === wrong: partial — no default row, so the first hit of a path raises
  @spec new() :: :ets.table()
  def new, do: :ets.new(:hits, [:set, :public, write_concurrency: true])

  @spec hit(:ets.table(), String.t()) :: pos_integer()
  def hit(table, path), do: :ets.update_counter(table, path, {2, 1})
  # === wrong: partial — a :protected table, so only the process that created it can count
  @spec new() :: :ets.table()
  def new, do: :ets.new(:hits, [:set, write_concurrency: true])

  @spec hit(:ets.table(), String.t()) :: pos_integer()
  def hit(table, path), do: :ets.update_counter(table, path, {2, 1}, {path, 0})
  # === wrong: partial — reads the count, then writes the next one in a separate call
  @spec new() :: :ets.table()
  def new, do: :ets.new(:hits, [:set, :public, write_concurrency: true])

  @spec hit(:ets.table(), String.t()) :: pos_integer()
  def hit(table, path) do
    next = :ets.lookup_element(table, path, 2, 0) + 1
    true = :ets.insert(table, {path, next})
    next
  end
  # <<<

  @spec count(:ets.table(), String.t()) :: non_neg_integer()
  def count(table, path), do: :ets.lookup_element(table, path, 2, 0)
end
