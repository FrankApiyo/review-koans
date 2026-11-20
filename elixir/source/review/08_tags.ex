defmodule Review.Ch08.Tags do
  @moduledoc """
  Note tags. `set_note_tags/3` replaces the tags on one of the scope's notes with the tags
  named `names`, creating those the scope's user does not have yet. Each user has their own
  tags, so two users may each have a tag of the same name.
  """

  import Ecto.Changeset, only: [change: 1, put_assoc: 3]

  alias Course.Ch08.{Note, Scope, Tag}
  alias Support.Repo

  @spec set_note_tags(Scope.t(), %Note{}, [String.t()]) ::
          {:ok, %Note{}} | {:error, Ecto.Changeset.t()}
  def set_note_tags(%Scope{} = scope, %Note{} = note, names) do
    rows = for name <- names, do: %{user_id: scope.user.id, name: name}
    # >>> fix
    # also: |> put_assoc(:tags, tags) — a reviewer points at the assoc that replaces the note's tags with only the rows the insert returned
    {_count, tags} = Repo.insert_all(Tag, rows, on_conflict: :nothing, returning: true)
    # === fixed
    require Ecto.Query
    Repo.insert_all(Tag, rows, on_conflict: :nothing)
    query = Ecto.Query.where(Tag, [t], t.user_id == ^scope.user.id and t.name in ^names)
    tags = Repo.all(query)
    # === alt: an upsert that returns every row, the ones that existed included
    {_count, tags} =
      Repo.insert_all(Tag, rows,
        on_conflict: {:replace, [:name]},
        conflict_target: [:user_id, :name],
        returning: true
      )
    # === wrong: refuses — attaches no tags
    _ = rows
    tags = []
    # === wrong: partial — reads the tags back by name alone, another user's included
    require Ecto.Query
    Repo.insert_all(Tag, rows, on_conflict: :nothing)
    tags = Repo.all(Ecto.Query.where(Tag, [t], t.name in ^names))
    # === wrong: partial — reads back only the names it did not insert, by name alone
    require Ecto.Query
    {_count, new} = Repo.insert_all(Tag, rows, on_conflict: :nothing, returning: true)
    missing = names -- Enum.map(new, & &1.name)
    tags = new ++ Repo.all(Ecto.Query.where(Tag, [t], t.name in ^missing))
    # === wrong: partial — reads back every tag the user has, not only the ones named
    require Ecto.Query
    Repo.insert_all(Tag, rows, on_conflict: :nothing)
    tags = Repo.all(Ecto.Query.where(Tag, [t], t.user_id == ^scope.user.id))
    # <<<

    note
    |> Repo.preload(:tags)
    |> change()
    |> put_assoc(:tags, tags)
    |> Repo.update()
  end
end
