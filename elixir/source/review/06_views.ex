defmodule Review.Ch06.Views do
  @moduledoc """
  View counts. Each page load calls `bump/1` with the post it rendered, and each load counts
  once.
  """

  alias Course.Ch06.Post
  alias Support.Repo

  @spec bump(%Post{}) :: :ok
  def bump(%Post{} = post) do
    # >>> fix
    # also: def bump(%Post{} = post) do — a reviewer points at the head that takes a post loaded earlier, whose count may be stale
    post |> Ecto.Changeset.change(views: post.views + 1) |> Repo.update!()
    # === fixed
    require Ecto.Query
    {1, _} = Repo.update_all(Ecto.Query.where(Post, id: ^post.id), inc: [views: 1])
    # === alt: one SQL update, in lower case, that adds to the stored count
    Repo.query!("update blog_posts set views = views + 1 where id = ?", [post.id])
    # === alt: the same update_all, inside a transaction
    require Ecto.Query
    query = Ecto.Query.where(Post, id: ^post.id)
    {:ok, {1, _}} = Repo.transact(fn -> {:ok, Repo.update_all(query, inc: [views: 1])} end)
    # === wrong: refuses — counts nothing
    _ = post
    # === wrong: partial — reads the post again, then writes the count back in a second query
    fresh = Repo.get!(Post, post.id)
    fresh |> Ecto.Changeset.change(views: fresh.views + 1) |> Repo.update!()
    # === wrong: partial — one UPDATE, but it sets the count read earlier
    require Ecto.Query
    Repo.update_all(Ecto.Query.where(Post, id: ^post.id), set: [views: post.views + 1])
    # <<<
    :ok
  end
end
