defmodule Review.Ch04.Warmup do
  @moduledoc """
  Warms a cache at boot. It runs `work` once under the app's supervisor and then stops; if
  `work` crashes, the supervisor runs it again.
  """

  use GenServer

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
