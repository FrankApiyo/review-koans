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
    require Ecto.Query
    Repo.insert_all(Tag, rows, on_conflict: :nothing)
    query = Ecto.Query.where(Tag, [t], t.user_id == ^scope.user.id and t.name in ^names)
    tags = Repo.all(query)

    note
    |> Repo.preload(:tags)
    |> change()
    |> put_assoc(:tags, tags)
    |> Repo.update()
  end
end
