defmodule Review.Ch05.Jobs do
  @moduledoc """
  Workers share a table of job claims, so that each job is processed by one worker.
  `claim/3` records `worker` as the owner of `job` and returns `:ok`, or `{:error, :taken}`
  when the job is already claimed; `owner/2` returns a job's worker, or `nil`.
  """

  @spec new() :: :ets.table()
  def new, do: :ets.new(:claims, [:set, :public])

  @spec claim(:ets.table(), term(), term()) :: :ok | {:error, :taken}
  def claim(table, job, worker) do
    # >>> fix
    :ets.insert(table, {job, worker})
    :ok
    # === fixed
    if :ets.insert_new(table, {job, worker}), do: :ok, else: {:error, :taken}
    # === alt: a cheap check first, while insert_new still makes the decision
    cond do
      :ets.member(table, job) -> {:error, :taken}
      :ets.insert_new(table, {job, worker}) -> :ok
      true -> {:error, :taken}
    end
    # === wrong: refuses — reports every job as taken
    _ = {table, job, worker}
    {:error, :taken}
    # === wrong: partial — looks the job up, then inserts in a second call
    case :ets.lookup(table, job) do
      [] ->
        :ets.insert(table, {job, worker})
        :ok

      [_claimed] ->
        {:error, :taken}
    end
    # === wrong: partial — asks member?, then inserts in a second call
    if :ets.member(table, job) do
      {:error, :taken}
    else
      :ets.insert(table, {job, worker})
      :ok
    end
    # <<<
  end

  @spec owner(:ets.table(), term()) :: term()
  def owner(table, job) do
    case :ets.lookup(table, job) do
      [{^job, worker}] -> worker
      [] -> nil
    end
  end
end
