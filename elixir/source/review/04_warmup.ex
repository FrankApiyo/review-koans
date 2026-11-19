defmodule Review.Ch04.Warmup do
  @moduledoc """
  Warms a cache at boot. It runs `work` once under the app's supervisor and then stops; if
  `work` crashes, the supervisor runs it again.
  """

  # >>> fix
  # also: {:stop, :normal, work} — a reviewer points at the normal stop that a :permanent child is restarted after
  use GenServer
  # === fixed
  use GenServer, restart: :transient
  # === alt: a child_spec that sets restart: :transient
  use GenServer

  @spec child_spec((-> any())) :: Supervisor.child_spec()
  def child_spec(work) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [work]}, restart: :transient}
  end
  # === wrong: refuses — a child_spec that never runs the work
  use GenServer, restart: :transient

  @spec child_spec((-> any())) :: Supervisor.child_spec()
  def child_spec(_work), do: %{id: __MODULE__, start: {Function, :identity, [:ignore]}}
  # === wrong: partial — :temporary never runs a crashed job again
  use GenServer, restart: :temporary
  # <<<

  @spec start_link((-> any())) :: GenServer.on_start()
  def start_link(work), do: GenServer.start_link(__MODULE__, work)

  @impl true
  def init(work), do: {:ok, work, {:continue, :run}}

  @impl true
  def handle_continue(:run, work) do
    work.()
    {:stop, :normal, work}
  end
end
