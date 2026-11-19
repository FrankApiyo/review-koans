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
end
