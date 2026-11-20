defmodule Review.Ch06.Views do
  @moduledoc """
  View counts. Each page load calls `bump/1` with the post it rendered, and each load counts
  once.
  """

  alias Course.Ch06.Post
  alias Support.Repo

  @spec bump(%Post{}) :: :ok
  def bump(%Post{} = post) do
    post |> Ecto.Changeset.change(views: post.views + 1) |> Repo.update!()
    :ok
  end
end
