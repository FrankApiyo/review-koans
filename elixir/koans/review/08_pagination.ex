defmodule Review.Ch08.Pagination do
  @moduledoc """
  The notes list, a page at a time. `page/3` returns up to `limit` of the scope's notes,
  ordered by `updated_at`, then `id`, both descending. `cursor` is `nil` for the first page,
  then `{updated_at, id}` of the last note on the page before.
  """

  import Ecto.Query

  alias Course.Ch08.{Note, Scope}
  alias Support.Repo

  @spec page(Scope.t(), {DateTime.t(), pos_integer()} | nil, pos_integer()) :: [%Note{}]
  def page(%Scope{} = scope, cursor, limit) do
    from(n in Note,
      where: n.user_id == ^scope.user.id,
      order_by: [desc: n.updated_at, desc: n.id],
      limit: ^limit
    )
    |> after_cursor(cursor)
    |> Repo.all()
  end

  defp after_cursor(query, nil), do: query

  defp after_cursor(query, {updated_at, _id}), do: where(query, [n], n.updated_at < ^updated_at)
end
