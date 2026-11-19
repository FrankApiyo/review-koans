defmodule Review.Ch04.Tree do
  @moduledoc """
  The catalog's supervision tree. `Course.Ch04.Store` holds the rows the tree is started
  with, and `Course.Ch04.Cache` serves price lookups from a copy of them.
  """

  use Supervisor

  alias Course.Ch04.{Cache, Store}

  @spec start_link([{String.t(), non_neg_integer()}]) :: Supervisor.on_start()
  def start_link(rows), do: Supervisor.start_link(__MODULE__, rows)

  @impl true
  def init(rows) do
    Supervisor.init([Cache, {Store, rows}], strategy: :one_for_one)
  end
end
