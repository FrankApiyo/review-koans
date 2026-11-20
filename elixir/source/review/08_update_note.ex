defmodule Review.Ch08.UpdateNote do
  @moduledoc """
  Note edits. `update_note/2` saves `attrs`, the editor's form, onto `note`, the copy the editor
  loaded, and returns `{:ok, note}`. The form sends back the `lock_version` it was rendered
  with. A save made from a copy that another tab has saved over since returns
  `{:error, changeset}` with an error on `:lock_version`, and changes nothing.
  """

  import Ecto.Changeset

  alias Course.Ch08.Note
  alias Support.Repo

  @spec update_note(%Note{}, map()) :: {:ok, %Note{}} | {:error, Ecto.Changeset.t()}
  def update_note(%Note{} = note, attrs) do
    note
    |> Note.changeset(attrs)
    |> cast(attrs, [:lock_version])
    # >>> fix
    # also: |> cast(attrs, [:lock_version]) — a reviewer points at the version that is cast but never checked
    |> Repo.update()
    # === fixed
    |> optimistic_lock(:lock_version)
    |> Repo.update(
      stale_error_field: :lock_version,
      stale_error_message: "was changed in another tab"
    )
    # === alt: the stale error under Ecto's default message
    |> optimistic_lock(:lock_version)
    |> Repo.update(stale_error_field: :lock_version)
    # === wrong: refuses — saves nothing
    |> Map.put(:valid?, false)
    |> Repo.update()
    # === wrong: partial — locks, but a stale save raises Ecto.StaleEntryError instead of returning an error
    |> optimistic_lock(:lock_version)
    |> Repo.update()
    # === wrong: partial — names the stale error field, but nothing checks the version
    |> Repo.update(stale_error_field: :lock_version)
    # <<<
  end
end
