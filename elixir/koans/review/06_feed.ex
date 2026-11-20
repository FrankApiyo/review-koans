defmodule Review.Ch06.Feed do
  @moduledoc """
  A user's profile page. `with_comments/1` returns every post `user` wrote, in id order, each
  with its `comments` loaded.
  """

  import Ecto.Query

  alias Course.Ch06.{Post, User}
  alias Support.Repo

  @spec with_comments(%User{}) :: [%Post{}]
  def with_comments(user) do
    posts = Repo.all(from p in Post, where: p.user_id == ^user.id, order_by: p.id)
    Enum.map(posts, &Repo.preload(&1, :comments))
  end
end
