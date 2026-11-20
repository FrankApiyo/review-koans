defmodule Review.Ch08.FetchNote do
  @moduledoc """
  Opens a note. `fetch_note/2` returns `{:ok, note}` for one of the scope's notes, and
  `{:error, :not_found}` for any other `id`. The id comes from the URL or from a
  `phx-value-id`.
  """

  alias Course.Ch08.{Note, Scope}
  alias Support.Repo

  @spec fetch_note(Scope.t(), term()) :: {:ok, %Note{}} | {:error, :not_found}
  def fetch_note(%Scope{} = scope, id) do
    # >>> fix
    # also: def fetch_note(%Scope{} = scope, id) do — a reviewer points at the head that takes any id the client sends
    case Repo.get_by(Note, id: id, user_id: scope.user.id) do
      %Note{} = note -> {:ok, note}
      nil -> {:error, :not_found}
    end
    # === fixed
    with {:ok, id} <- Course.Ch08.Id.cast(id),
         %Note{} = note <- Repo.get_by(Note, id: id, user_id: scope.user.id) do
      {:ok, note}
    else
      _ -> {:error, :not_found}
    end
    # === alt: Integer.parse, with the id's 64-bit range checked
    with {id, ""} when id in 1..9_223_372_036_854_775_807//1 <- Integer.parse(to_string(id)),
         %Note{} = note <- Repo.get_by(Note, id: id, user_id: scope.user.id) do
      {:ok, note}
    else
      _ -> {:error, :not_found}
    end
    # === wrong: refuses — finds nothing, whatever the id
    _ = {scope, id}
    {:error, :not_found}
    # === wrong: partial — Integer.parse alone, so an id past the 64-bit range still reaches the database
    with {id, ""} <- Integer.parse(to_string(id)),
         %Note{} = note <- Repo.get_by(Note, id: id, user_id: scope.user.id) do
      {:ok, note}
    else
      _ -> {:error, :not_found}
    end
    # === wrong: partial — Ecto.Type.cast(:id, _) alone, which passes nil and ids past the 64-bit range
    with {:ok, id} <- Ecto.Type.cast(:id, id),
         %Note{} = note <- Repo.get_by(Note, id: id, user_id: scope.user.id) do
      {:ok, note}
    else
      _ -> {:error, :not_found}
    end
    # <<<
  end
end
