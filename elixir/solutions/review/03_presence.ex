defmodule Review.Ch03.Presence do
  @moduledoc """
  Tracks who is online. A process calls `join/2` with its user's name; afterwards
  `whoami/1`, called from that same process, returns the name, and returns `nil` in any
  process that has not joined.
  """

  use GenServer

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, %{})

  @spec join(GenServer.server(), String.t()) :: :ok
  def join(presence, name), do: GenServer.call(presence, {:join, name})

  @spec whoami(GenServer.server()) :: String.t() | nil
  def whoami(presence), do: GenServer.call(presence, :whoami)

  @impl true
  def init(names), do: {:ok, names}

  @impl true
  def handle_call({:join, name}, {pid, _tag}, names), do: {:reply, :ok, Map.put(names, pid, name)}
  def handle_call(:whoami, {pid, _tag}, names), do: {:reply, Map.get(names, pid), names}
end
