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
    # >>> fix
    # also: def init(:ok) do — a reviewer points at the callback whose one job is the child list
    Supervisor.init([Producer, Consumer], strategy: :one_for_one)
    # === fixed
    Supervisor.init([Producer, Consumer], strategy: :rest_for_one)
    # === alt: the pair under its own :rest_for_one supervisor
    pair = %{
      id: :pair,
      type: :supervisor,
      start: {Supervisor, :start_link, [[Producer, Consumer], [strategy: :rest_for_one]]}
    }

    Supervisor.init([pair], strategy: :one_for_one)
    # === wrong: refuses — supervises no consumer
    Supervisor.init([Producer], strategy: :rest_for_one)
    # === wrong: partial — :one_for_all also restarts the producer when only the consumer crashes
    Supervisor.init([Producer, Consumer], strategy: :one_for_all)
    # === wrong: partial — :rest_for_one with the consumer started before the producer
    Supervisor.init([Consumer, Producer], strategy: :rest_for_one)
    # <<<
  end
end
