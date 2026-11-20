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
    # >>> fix
    Repo.transact(fn ->
      with {:ok, post} <- Repo.insert(post_changeset(user, attrs)),
           :ok <- notify.(post),
           {:ok, _comment} <- Repo.insert(comment_changeset(post, attrs)) do
        {:ok, post}
      end
    end)
    # === fixed
    result =
      Repo.transact(fn ->
        with {:ok, post} <- Repo.insert(post_changeset(user, attrs)),
             {:ok, _comment} <- Repo.insert(comment_changeset(post, attrs)) do
          {:ok, post}
        end
      end)

    with {:ok, post} <- result, :ok <- notify.(post), do: {:ok, post}
    # === alt: an Ecto.Multi, then notify once it has committed
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:post, post_changeset(user, attrs))
    |> Ecto.Multi.insert(:comment, &comment_changeset(&1.post, attrs))
    |> Repo.transact()
    |> case do
      {:ok, %{post: post}} -> with :ok <- notify.(post), do: {:ok, post}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
    # === wrong: refuses — never publishes
    _ = {user, attrs, notify}
    {:error, :unavailable}
    # === wrong: partial — tells followers after the transaction, whatever it returned
    result =
      Repo.transact(fn ->
        with {:ok, post} <- Repo.insert(post_changeset(user, attrs)),
             {:ok, _comment} <- Repo.insert(comment_changeset(post, attrs)) do
          {:ok, post}
        end
      end)

    :ok = notify.(result)
    result
    # <<<
  end

  defp post_changeset(user, attrs), do: Post.changeset(%Post{user_id: user.id}, attrs)

  defp comment_changeset(post, attrs) do
    %Comment{post_id: post.id}
    |> cast(%{"body" => attrs["first_comment"]}, [:body])
    |> validate_required([:body])
  end
end
