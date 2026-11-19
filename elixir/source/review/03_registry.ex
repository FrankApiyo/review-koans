defmodule Review.Ch03.Registry do
  @moduledoc """
  Keeps a session for each client process. A client calls `register/1` once when it starts;
  `count/1` returns how many registered clients are still running.
  """

  use GenServer

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, %{})

  @spec register(GenServer.server()) :: :ok
  def register(registry), do: GenServer.call(registry, :register)

  @spec count(GenServer.server()) :: non_neg_integer()
  def count(registry), do: GenServer.call(registry, :count)

  @impl true
  def init(sessions), do: {:ok, sessions}

  @impl true
  def handle_call(:register, {pid, _tag}, sessions) do
    ref = Process.monitor(pid)
    {:reply, :ok, Map.put(sessions, pid, ref)}
  end

  def handle_call(:count, _from, sessions), do: {:reply, map_size(sessions), sessions}
  # >>> fix
  # also: Process.monitor(pid) — the monitor whose :DOWN nobody handles
  # === fixed

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, sessions),
    do: {:noreply, Map.delete(sessions, pid)}
  # === alt: find the session by its monitor ref

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, sessions),
    do: {:noreply, Map.reject(sessions, fn {_pid, session} -> session == ref end)}
  # === wrong: refuses — drops every session on any message

  @impl true
  def handle_info(_message, _sessions), do: {:noreply, %{}}
  # === wrong: partial — deletes by ref, but the sessions are keyed by pid

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, sessions),
    do: {:noreply, Map.delete(sessions, ref)}
  # === wrong: partial — removes only clients that end normally

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, :normal}, sessions),
    do: {:noreply, Map.delete(sessions, pid)}
  # <<<
end
