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
    # >>> fix
    posts = Repo.all(from p in Post, where: p.user_id == ^user.id, order_by: p.id)
    Enum.map(posts, &Repo.preload(&1, :comments))
    # === fixed
    posts = Repo.all(from p in Post, where: p.user_id == ^user.id, order_by: p.id)
    Repo.preload(posts, :comments)
    # === alt: preload in the query
    Repo.all(from p in Post, where: p.user_id == ^user.id, order_by: p.id, preload: :comments)
    # === alt: a left join preload, which keeps a post that has no comments
    Repo.all(
      from p in Post,
        where: p.user_id == ^user.id,
        left_join: c in assoc(p, :comments),
        order_by: [p.id, c.id],
        preload: [comments: c]
    )
    # === wrong: refuses — lists no posts
    _ = user
    []
    # === wrong: partial — an inner join preload, which drops a post that has no comments
    Repo.all(
      from p in Post,
        where: p.user_id == ^user.id,
        join: c in assoc(p, :comments),
        order_by: [p.id, c.id],
        preload: [comments: c]
    )
    # === wrong: partial — loads each post's comments through its association, one query a post
    posts = Repo.all(from p in Post, where: p.user_id == ^user.id, order_by: p.id)
    Enum.map(posts, &%{&1 | comments: Repo.all(Ecto.assoc(&1, :comments))})
    # <<<
  end
end
