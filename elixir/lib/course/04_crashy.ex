defmodule Course.Ch04.Crashy do
  @moduledoc """
  A counter that sends `{:started, id, pid}` to `test` each time it starts. `bump/1` adds one
  and returns the new count; `stop_with/2` makes it stop with the given reason. Its child id
  is the `id` it is started with.
  """

  use GenServer

  @spec child_spec({atom(), pid()}) :: Supervisor.child_spec()
  def child_spec({id, test}), do: %{id: id, start: {__MODULE__, :start_link, [{id, test}]}}

  @spec start_link({atom(), pid()}) :: GenServer.on_start()
  def start_link({id, test}), do: GenServer.start_link(__MODULE__, {id, test})

  @spec bump(pid()) :: pos_integer()
  def bump(pid), do: GenServer.call(pid, :bump)

  @spec stop_with(pid(), term()) :: :ok
  def stop_with(pid, reason), do: GenServer.cast(pid, {:stop_with, reason})

  @impl true
  def init({id, test}) do
    send(test, {:started, id, self()})
    {:ok, 0}
  end

  @impl true
  def handle_call(:bump, _from, count), do: {:reply, count + 1, count + 1}

  @impl true
  def handle_cast({:stop_with, reason}, count), do: {:stop, reason, count}
end
