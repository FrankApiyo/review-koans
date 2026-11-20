defmodule Review.Ch06.Publish do
  @moduledoc """
  Publishes a post with its first comment: both are saved, or neither is. Followers hear about
  each published post through `notify`, which returns `:ok`.
  """

  import Ecto.Changeset

  alias Course.Ch06.{Comment, Post, User}
  alias Support.Repo

  @spec publish(%User{}, map(), (%Post{} -> :ok)) :: {:ok, %Post{}} | {:error, term()}
  def publish(user, attrs, notify) do
    Repo.transact(fn ->
      with {:ok, post} <- Repo.insert(post_changeset(user, attrs)),
           :ok <- notify.(post),
           {:ok, _comment} <- Repo.insert(comment_changeset(post, attrs)) do
        {:ok, post}
      end
    end)
  end

  defp post_changeset(user, attrs), do: Post.changeset(%Post{user_id: user.id}, attrs)

  defp comment_changeset(post, attrs) do
    %Comment{post_id: post.id}
    |> cast(%{"body" => attrs["first_comment"]}, [:body])
    |> validate_required([:body])
  end
end
