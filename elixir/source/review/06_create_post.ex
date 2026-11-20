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
    # >>> fix
    changeset = cast(%Post{user_id: user.id}, attrs, [:title, :body, :user_id])
    # === fixed
    changeset = cast(%Post{user_id: user.id}, attrs, [:title, :body])
    # === alt: the schema's own changeset, which casts the title and body
    changeset = Post.changeset(%Post{user_id: user.id}, attrs)
    # === alt: the author put on the changeset after cast
    changeset = %Post{} |> cast(attrs, [:title, :body]) |> put_change(:user_id, user.id)
    # === wrong: refuses — ignores the form, so no post ever has a title
    _ = attrs
    changeset = cast(%Post{user_id: user.id}, %{}, [:title, :body])
    # === wrong: partial — leaves the author out of the struct as well as out of cast
    _ = user
    changeset = cast(%Post{}, attrs, [:title, :body])
    # === wrong: partial — deletes an atom key, but form params have string keys
    params = Map.delete(attrs, :user_id)
    changeset = cast(%Post{user_id: user.id}, params, [:title, :body, :user_id])
    # <<<
    changeset |> validate_required([:title]) |> Repo.insert()
  end
end
