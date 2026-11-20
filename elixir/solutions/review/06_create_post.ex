defmodule Review.Ch06.CreatePost do
  @moduledoc """
  Saves the new-post form. `create/2` returns `{:ok, post}` with the signed-in `user` as its
  author, or `{:error, changeset}` when the title is missing. `attrs` are the form's params.
  """

  import Ecto.Changeset

  alias Course.Ch06.{Post, User}
  alias Support.Repo

  @spec create(%User{}, map()) :: {:ok, %Post{}} | {:error, Ecto.Changeset.t()}
  def create(user, attrs) do
    changeset = cast(%Post{user_id: user.id}, attrs, [:title, :body])
    changeset |> validate_required([:title]) |> Repo.insert()
  end
end
