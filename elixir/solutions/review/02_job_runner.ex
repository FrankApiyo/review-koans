defmodule Review.Ch02.JobRunner do
  @moduledoc """
  A server that runs each job in a linked process. It traps exits so a failing job cannot
  take it down. `stats/1` returns how many jobs finished and the exit reasons of those that
  failed, most recent first.
  """

  use GenServer

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, :ok)

  @spec run(GenServer.server(), (-> term())) :: :ok
  def run(server, job), do: GenServer.cast(server, {:run, job})

  @spec stats(GenServer.server()) :: %{done: non_neg_integer(), failed: [term()]}
  def stats(server), do: GenServer.call(server, :stats)

  @impl true
  def init(:ok) do
    Process.flag(:trap_exit, true)
    {:ok, %{done: 0, failed: []}}
  end

  @impl true
  def handle_cast({:run, job}, state) do
    spawn_link(job)
    {:noreply, state}
  end

  @impl true
  def handle_call(:stats, _from, state), do: {:reply, state, state}

  @impl true
  def handle_info({:EXIT, _pid, :normal}, state) do
    {:noreply, %{state | done: state.done + 1}}
  end

  def handle_info({:EXIT, _pid, reason}, state) do
    {:noreply, %{state | failed: [reason | state.failed]}}
  end
end
