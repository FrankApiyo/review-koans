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
  # >>> fix
  # also: Process.flag(:trap_exit, true) — a reviewer points at the trap that turns every job's exit, :normal included, into a message
  def handle_info({:EXIT, _pid, reason}, state) when reason != :normal do
    {:noreply, %{state | failed: [reason | state.failed]}}
  end
  # === fixed
  def handle_info({:EXIT, _pid, :normal}, state) do
    {:noreply, %{state | done: state.done + 1}}
  end

  def handle_info({:EXIT, _pid, reason}, state) do
    {:noreply, %{state | failed: [reason | state.failed]}}
  end
  # === alt: one clause that branches on the reason
  def handle_info({:EXIT, _pid, reason}, state) do
    case reason do
      :normal -> {:noreply, %{state | done: state.done + 1}}
      _failure -> {:noreply, %{state | failed: [reason | state.failed]}}
    end
  end
  # === wrong: refuses — ignores every job's exit
  def handle_info({:EXIT, _pid, _reason}, state) do
    {:noreply, state}
  end
  # === wrong: partial — a catch-all keeps the server up but never counts a finished job
  def handle_info({:EXIT, _pid, reason}, state) when reason != :normal do
    {:noreply, %{state | failed: [reason | state.failed]}}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end
  # === wrong: partial — a clause for :normal that ignores it, so a finished job is never counted
  def handle_info({:EXIT, _pid, :normal}, state) do
    {:noreply, state}
  end

  def handle_info({:EXIT, _pid, reason}, state) do
    {:noreply, %{state | failed: [reason | state.failed]}}
  end
  # <<<
end
