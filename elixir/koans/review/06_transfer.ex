defmodule Review.Ch06.Transfer do
  @moduledoc """
  Hands a post to another author. `move_post/3` gives `user`'s post `post_id` to
  `new_owner_id` and returns `{:ok, post}`, or `{:error, :not_found}` when `user` has no such
  post. `post_id` comes from the URL.
  """

  import Ecto.Changeset, only: [change: 2]
  import Ecto.Query

  alias Course.Ch06.{Post, User}
  alias Ecto.Multi
  alias Support.Repo

  @spec move_post(%User{}, term(), pos_integer()) ::
          {:ok, %Post{}} | {:error, :not_found | Ecto.Changeset.t()}
  def move_post(user, post_id, new_owner_id) do
    Multi.new()
    |> Multi.one(:post, from(p in Post, where: p.id == ^post_id and p.user_id == ^user.id))
    |> Multi.run(:check, fn _repo, %{post: post} -> found(post) end)
    |> Multi.update(:moved, fn %{check: post} -> change(post, user_id: new_owner_id) end)
    |> Repo.transact()
    |> case do
      {:ok, %{moved: post}} -> {:ok, post}
      {:error, :check, :not_found, _changes} -> {:error, :not_found}
      {:error, _step, changeset, _changes} -> {:error, changeset}
    end
  end

  defp found(nil), do: {:error, :not_found}
  defp found(post), do: {:ok, post}
end
