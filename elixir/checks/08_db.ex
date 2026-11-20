defmodule Checks.Ch08.Db do
  @moduledoc false

  alias Course.Ch08.{Note, Notebook, Scope, Tag, User}
  alias Support.Repo

  @at ~U[2026-01-01 09:00:00Z]

  @doc "A user, as the scope a signed-in request carries."
  @spec scope!(String.t()) :: Scope.t()
  def scope!(name), do: Scope.for_user(Repo.insert!(%User{email: name <> "@example.com"}))

  @spec notebook!(Scope.t(), String.t()) :: %Notebook{}
  def notebook!(%Scope{user: user}, name) do
    Repo.insert!(%Notebook{name: name, user_id: user.id, inserted_at: @at, updated_at: @at})
  end

  @doc "A note in `notebook`, saved at `opts[:at]` with `opts[:body]`; no clock is read."
  @spec note!(%Notebook{}, String.t(), keyword()) :: %Note{}
  def note!(%Notebook{} = notebook, title, opts \\ []) do
    at = Keyword.get(opts, :at, @at)

    Repo.insert!(%Note{
      title: title,
      body: Keyword.get(opts, :body, ""),
      notebook_id: notebook.id,
      user_id: notebook.user_id,
      inserted_at: at,
      updated_at: at
    })
  end

  @spec tag!(Scope.t(), String.t()) :: %Tag{}
  def tag!(%Scope{user: user}, name), do: Repo.insert!(%Tag{name: name, user_id: user.id})

  @doc "The name and owner of each tag stored on the note, sorted."
  @spec stored_tags(%Note{}) :: [{String.t(), pos_integer()}]
  def stored_tags(%Note{id: id}) do
    note = Note |> Repo.get!(id) |> Repo.preload(:tags)
    note.tags |> Enum.map(&{&1.name, &1.user_id}) |> Enum.sort()
  end

  @spec raised((-> any())) :: module() | :nothing_raised
  def raised(fun) do
    fun.()
    :nothing_raised
  rescue
    error -> error.__struct__
  end

  @doc "The messages waiting in the caller's mailbox."
  @spec mailbox() :: [term()]
  def mailbox do
    {:messages, messages} = Process.info(self(), :messages)
    messages
  end
end
