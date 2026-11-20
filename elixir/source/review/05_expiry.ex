defmodule Review.Ch05.Expiry do
  @moduledoc """
  Sweeps a cache table of `{key, value, expires_at}` rows, with times in whole seconds.
  `expire/2` deletes every row that has expired by `now`, a row that expires exactly at `now`
  included, and returns how many rows it deleted.
  """

  @spec expire(:ets.table(), integer()) :: non_neg_integer()
  def expire(table, now) do
    # >>> fix
    :ets.select_delete(table, [{{:_, :_, :"$1"}, [{:<, :"$1", now}], [true]}])
    # === fixed
    :ets.select_delete(table, [{{:_, :_, :"$1"}, [{:"=<", :"$1", now}], [true]}])
    # === alt: the guard turned around
    :ets.select_delete(table, [{{:_, :_, :"$1"}, [{:>=, now, :"$1"}], [true]}])
    # === alt: the strict guard moved one second on, since times are whole seconds
    :ets.select_delete(table, [{{:_, :_, :"$1"}, [{:<, :"$1", now + 1}], [true]}])
    # === wrong: refuses — deletes nothing
    _ = {table, now}
    0
    # === wrong: partial — returns each expired row instead of true, so select_delete deletes none
    :ets.select_delete(table, [{{:_, :_, :"$1"}, [{:"=<", :"$1", now}], [:"$_"]}])
    # === wrong: partial — Elixir's <=, which match specs do not know
    :ets.select_delete(table, [{{:_, :_, :"$1"}, [{:<=, :"$1", now}], [true]}])
    # <<<
  end
end
