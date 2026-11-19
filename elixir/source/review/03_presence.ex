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
  # >>> fix
  def handle_call({:join, name}, from, names), do: {:reply, :ok, Map.put(names, from, name)}
  def handle_call(:whoami, from, names), do: {:reply, Map.get(names, from), names}
  # === fixed
  def handle_call({:join, name}, {pid, _tag}, names), do: {:reply, :ok, Map.put(names, pid, name)}
  def handle_call(:whoami, {pid, _tag}, names), do: {:reply, Map.get(names, pid), names}
  # === alt: take the pid out of from with elem/2
  def handle_call({:join, name}, from, names),
    do: {:reply, :ok, Map.put(names, elem(from, 0), name)}

  def handle_call(:whoami, from, names), do: {:reply, Map.get(names, elem(from, 0)), names}
  # === wrong: refuses — turns every join away
  def handle_call({:join, _name}, _from, names), do: {:reply, {:error, :closed}, names}
  def handle_call(:whoami, _from, names), do: {:reply, nil, names}
  # === wrong: partial — keys by self(), which is the server, so every process shares one name
  def handle_call({:join, name}, _from, names), do: {:reply, :ok, Map.put(names, self(), name)}
  def handle_call(:whoami, _from, names), do: {:reply, Map.get(names, self()), names}
  # === wrong: partial — keys join by the caller's pid but still looks up by from
  def handle_call({:join, name}, {pid, _tag}, names), do: {:reply, :ok, Map.put(names, pid, name)}
  def handle_call(:whoami, from, names), do: {:reply, Map.get(names, from), names}
  # <<<
end
