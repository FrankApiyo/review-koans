defmodule Review.Ch05.Hits do
  @moduledoc """
  Counts page hits. Request processes share one table: `hit/2` adds one hit to `path` and
  returns its count so far, and `count/2` returns a path's count, 0 for a path nobody visited.
  """

  @spec new() :: :ets.table()
  def new, do: :ets.new(:hits, [:set, :public, write_concurrency: true])

  @spec hit(:ets.table(), String.t()) :: pos_integer()
  def hit(table, path), do: :ets.update_counter(table, path, {2, 1}, {path, 0})

  @spec count(:ets.table(), String.t()) :: non_neg_integer()
  def count(table, path), do: :ets.lookup_element(table, path, 2, 0)
end
