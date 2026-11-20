defmodule Review.Ch05.Expiry do
  @moduledoc """
  Sweeps a cache table of `{key, value, expires_at}` rows, with times in whole seconds.
  `expire/2` deletes every row that has expired by `now`, a row that expires exactly at `now`
  included, and returns how many rows it deleted.
  """

  @spec expire(:ets.table(), integer()) :: non_neg_integer()
  def expire(table, now) do
    :ets.select_delete(table, [{{:_, :_, :"$1"}, [{:"=<", :"$1", now}], [true]}])
  end
end
