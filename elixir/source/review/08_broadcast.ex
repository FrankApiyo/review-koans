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

  # >>> fix
  # also: |> broadcast(scope, :note_saved) — a reviewer points at the call that hands every result, an error included, to the broadcast
  # also: |> broadcast(scope, :notebook_created) — a reviewer points at the call that hands every result, an error included, to the broadcast
  defp broadcast(result, scope, event) do
    {_, record} = result
    :ok = Phoenix.PubSub.broadcast(Support.PubSub, topic(scope), {event, record})
    result
  end
  # === fixed
  defp broadcast({:ok, record} = result, scope, event) do
    :ok = Phoenix.PubSub.broadcast(Support.PubSub, topic(scope), {event, record})
    result
  end

  defp broadcast(result, _scope, _event), do: result
  # === alt: a case on the result
  defp broadcast(result, scope, event) do
    case result do
      {:ok, record} -> :ok = Phoenix.PubSub.broadcast(Support.PubSub, topic(scope), {event, record})
      {:error, _changeset} -> :ok
    end

    result
  end
  # === wrong: refuses — announces nothing
  defp broadcast(result, _scope, _event), do: result
  # === wrong: partial — announces only saved notes, so a new notebook is never announced
  defp broadcast({:ok, %Note{} = note} = result, scope, event) do
    :ok = Phoenix.PubSub.broadcast(Support.PubSub, topic(scope), {event, note})
    result
  end

  defp broadcast(result, _scope, _event), do: result
  # === wrong: partial — matches {:ok, record}, so a failed save raises instead of returning its error
  defp broadcast(result, scope, event) do
    {:ok, record} = result
    :ok = Phoenix.PubSub.broadcast(Support.PubSub, topic(scope), {event, record})
    result
  end
  # <<<
end
