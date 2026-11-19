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
    # >>> fix
    # also: def init(rows) do — a reviewer points at the callback whose one job is the child list
    Supervisor.init([Cache, {Store, rows}], strategy: :one_for_one)
    # === fixed
    Supervisor.init([{Store, rows}, Cache], strategy: :one_for_one)
    # === alt: the store first, under :rest_for_one
    Supervisor.init([{Store, rows}, Cache], strategy: :rest_for_one)
    # === wrong: refuses — supervises no cache
    Supervisor.init([{Store, rows}], strategy: :one_for_one)
    # === wrong: partial — :one_for_all still starts the cache before the store
    Supervisor.init([Cache, {Store, rows}], strategy: :one_for_all)
    # === wrong: partial — :rest_for_one still starts the cache before the store
    Supervisor.init([Cache, {Store, rows}], strategy: :rest_for_one)
    # === wrong: partial — starts the store in init, outside the tree
    {:ok, _store} = Store.start_link(rows)
    Supervisor.init([Cache], strategy: :one_for_one)
    # <<<
  end
end
