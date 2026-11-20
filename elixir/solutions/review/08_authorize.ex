defmodule Review.Ch08.Authorize do
  @moduledoc """
  Notebook pages. `get_notebook!/2` returns the scope's notebook `id`, and raises
  `Ecto.NoResultsError` for any other id. `authorize!/2` is shared by every page that loads a
  record by id: it returns the record when the scope's user owns it.
  """

  alias Course.Ch08.{Notebook, Scope}
  alias Support.Repo

  @spec get_notebook!(Scope.t(), term()) :: %Notebook{}
  def get_notebook!(%Scope{} = scope, id), do: authorize!(scope, Repo.get!(Notebook, id))

  @spec authorize!(Scope.t(), struct()) :: struct()
  def authorize!(%Scope{user: %{id: id}}, %{user_id: id} = record), do: record
  def authorize!(_scope, %schema{}), do: raise(Ecto.NoResultsError, queryable: schema)
end
