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
    :ets.insert(table, {job, worker})
    :ok
  end

  @spec owner(:ets.table(), term()) :: term()
  def owner(table, job) do
    case :ets.lookup(table, job) do
      [{^job, worker}] -> worker
      [] -> nil
    end
  end
end
