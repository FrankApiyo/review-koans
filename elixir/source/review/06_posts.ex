defmodule Review.Ch06.Posts do
  @moduledoc """
  Post pages for the signed-in user. `get_post!/2` returns one of `user`'s posts by `id`, the id
  taken from the URL, and raises `Ecto.NoResultsError` when there is no such post.
  """

  alias Course.Ch06.{Post, User}
  alias Support.Repo

  @spec get_post!(%User{}, term()) :: %Post{}
  # >>> fix
  def get_post!(_user, id), do: Repo.get!(Post, id)
  # === fixed
  def get_post!(user, id), do: Repo.get_by!(Post, id: id, user_id: user.id)
  # === alt: a query scoped to the author, read with one!
  def get_post!(user, id) do
    require Ecto.Query
    Repo.one!(Ecto.Query.where(Post, [p], p.id == ^id and p.user_id == ^user.id))
  end
  # === alt: the user's own posts, through the association
  def get_post!(user, id), do: user |> Ecto.assoc(:posts) |> Repo.get!(id)
  # === wrong: refuses — raises for every id, the author's own included
  def get_post!(_user, _id), do: raise(Ecto.NoResultsError, queryable: Post)
  # === wrong: partial — loads the post, then raises a different error when someone else wrote it
  def get_post!(user, id) do
    post = Repo.get!(Post, id)
    if post.user_id == user.id, do: post, else: raise(ArgumentError, "forbidden")
  end
  # === wrong: partial — returns nil for someone else's post instead of raising
  def get_post!(user, id) do
    post = Repo.get!(Post, id)
    if post.user_id == user.id, do: post
  end
  # <<<
end
