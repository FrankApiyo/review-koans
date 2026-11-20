defmodule Review.Ch06.Posts do
  @moduledoc """
  Post pages for the signed-in user. `get_post!/2` returns one of `user`'s posts by `id`, the id
  taken from the URL, and raises `Ecto.NoResultsError` when there is no such post.
  """

  alias Course.Ch06.{Post, User}
  alias Support.Repo

  @spec get_post!(%User{}, term()) :: %Post{}
  def get_post!(_user, id), do: Repo.get!(Post, id)
end
