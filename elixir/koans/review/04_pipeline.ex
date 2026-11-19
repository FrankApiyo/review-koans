defmodule Review.Ch04.Pipeline do
  @moduledoc """
  Supervises the event pipeline. `Course.Ch04.Producer` records events, and
  `Course.Ch04.Consumer` forwards each pushed event to it.
  """

  use Supervisor

  alias Course.Ch04.{Consumer, Producer}

  @spec start_link(term()) :: Supervisor.on_start()
  def start_link(_arg), do: Supervisor.start_link(__MODULE__, :ok)

  @impl true
  def init(:ok) do
    Supervisor.init([Producer, Consumer], strategy: :one_for_one)
  end
end
