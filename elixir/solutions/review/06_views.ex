defmodule Review.Ch06.Views do
  @moduledoc """
  View counts. Each page load calls `bump/1` with the post it rendered, and each load counts
  once.
  """

  alias Course.Ch06.Post
  alias Support.Repo

  @spec bump(%Post{}) :: :ok
  def bump(%Post{} = post) do
    require Ecto.Query
    {1, _} = Repo.update_all(Ecto.Query.where(Post, id: ^post.id), inc: [views: 1])
    :ok
  end
end
