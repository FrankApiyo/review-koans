defmodule Review.Ch08.Broadcast do
  @moduledoc """
  Notebook writes, announced to the user's open tabs. `update_note/3` and `create_notebook/2`
  return what the repo returns, and each saved change is broadcast as `{event, record}` on
  `topic/1`.
  """

  import Ecto.Changeset

  alias Course.Ch08.{Note, Notebook, Scope}
  alias Support.Repo

  @spec topic(Scope.t()) :: String.t()
  def topic(%Scope{user: %{id: id}}), do: "notebooks:user:#{id}"

  @spec update_note(Scope.t(), %Note{}, map()) :: {:ok, %Note{}} | {:error, Ecto.Changeset.t()}
  def update_note(%Scope{} = scope, %Note{} = note, attrs) do
    note
    |> Note.changeset(attrs)
    |> Repo.update()
    |> broadcast(scope, :note_saved)
  end

  @spec create_notebook(Scope.t(), map()) :: {:ok, %Notebook{}} | {:error, Ecto.Changeset.t()}
  def create_notebook(%Scope{} = scope, attrs) do
    %Notebook{user_id: scope.user.id}
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> Repo.insert()
    |> broadcast(scope, :notebook_created)
  end

  defp broadcast(result, scope, event) do
    {_, record} = result
    :ok = Phoenix.PubSub.broadcast(Support.PubSub, topic(scope), {event, record})
    result
  end
end
