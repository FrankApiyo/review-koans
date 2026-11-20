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

      # >>> fix
      # also: where: fragment("? IN (SELECT rowid FROM notes_fts WHERE notes_fts MATCH ?)", n.id, ^match), — a reviewer points at the MATCH that receives the text built from what the user typed
      tokens ->
        Enum.map_join(tokens, " ", &("\"" <> &1 <> "\""))
      # === fixed
      tokens ->
        Enum.map_join(tokens, " ", &("\"" <> String.replace(&1, "\"", "\"\"") <> "\""))
      # === alt: strips the quotes, which the tokenizer drops anyway
      tokens ->
        Enum.map_join(tokens, " ", &("\"" <> String.replace(&1, "\"", "") <> "\""))
      # === wrong: refuses — finds nothing
      _tokens ->
        nil
      # === wrong: partial — passes the text through, so a word can be read as FTS5 syntax
      _tokens ->
        text
      # === wrong: partial — escapes quotes with a backslash, which FTS5 does not read as an escape
      tokens ->
        Enum.map_join(tokens, " ", &("\"" <> String.replace(&1, "\"", "\\\"") <> "\""))
      # === wrong: partial — quotes the whole text as one phrase, so the words must sit side by side
      _tokens ->
        "\"" <> String.replace(text, "\"", "\"\"") <> "\""
      # === wrong: partial — drops the quotes, but leaves the words unquoted, so a word can still be read as FTS5 syntax
      _tokens ->
        String.replace(text, "\"", "")
      # <<<
    end
  end
end
