defmodule Review.Ch08.Search do
  @moduledoc """
  Note search. `search/2` returns the scope's notes that hold every word of `text`, in any
  order, newest first; blank text finds nothing. `text` is whatever the user typed in the
  search box.
  """

  import Ecto.Query

  alias Course.Ch08.{Note, Scope}
  alias Support.Repo

  @spec search(Scope.t(), String.t()) :: [%Note{}]
  def search(%Scope{} = scope, text) do
    case fts_query(text) do
      nil -> []
      match -> Repo.all(matching(scope, match))
    end
  end

  defp matching(scope, match) do
    from n in Note,
      where: n.user_id == ^scope.user.id,
      where: fragment("? IN (SELECT rowid FROM notes_fts WHERE notes_fts MATCH ?)", n.id, ^match),
      order_by: [desc: n.updated_at, desc: n.id]
  end

  defp fts_query(text) do
    case String.split(text) do
      [] ->
        nil

      tokens ->
        Enum.map_join(tokens, " ", &("\"" <> &1 <> "\""))
    end
  end
end
