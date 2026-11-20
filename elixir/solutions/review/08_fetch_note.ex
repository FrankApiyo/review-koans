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
    with {:ok, id} <- Course.Ch08.Id.cast(id),
         %Note{} = note <- Repo.get_by(Note, id: id, user_id: scope.user.id) do
      {:ok, note}
    else
      _ -> {:error, :not_found}
    end
  end
end
