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

  # >>> fix
  defp after_cursor(query, {updated_at, _id}), do: where(query, [n], n.updated_at < ^updated_at)
  # === fixed
  defp after_cursor(query, {updated_at, id}) do
    where(query, [n], n.updated_at < ^updated_at or (n.updated_at == ^updated_at and n.id < ^id))
  end
  # === alt: a row-value comparison, with the cursor's timestamp typed
  defp after_cursor(query, {updated_at, id}) do
    where(
      query,
      [n],
      fragment("(?, ?) < (?, ?)", n.updated_at, n.id, type(^updated_at, :utc_datetime), ^id)
    )
  end
  # === wrong: refuses — every page after the first is empty
  defp after_cursor(query, _cursor), do: where(query, false)
  # === wrong: partial — <= keeps the notes that share the cursor's updated_at, the last one included
  defp after_cursor(query, {updated_at, _id}), do: where(query, [n], n.updated_at <= ^updated_at)
  # === wrong: partial — breaks the tie on a higher id, against the descending order
  defp after_cursor(query, {updated_at, id}) do
    where(query, [n], n.updated_at < ^updated_at or (n.updated_at == ^updated_at and n.id > ^id))
  end
  # === wrong: partial — a row-value comparison whose untyped timestamp is sent without its Z
  defp after_cursor(query, {updated_at, id}) do
    where(query, [n], fragment("(?, ?) < (?, ?)", n.updated_at, n.id, ^updated_at, ^id))
  end
  # === wrong: partial — requires both a lower id and an updated_at no later, so an older note with a higher id is skipped
  defp after_cursor(query, {updated_at, id}) do
    where(query, [n], n.updated_at <= ^updated_at and n.id < ^id)
  end
  # <<<
end
