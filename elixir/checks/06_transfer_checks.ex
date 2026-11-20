defmodule Checks.Ch06.Transfer do
  use Koans.Checks, review: Review.Ch06.Transfer

  alias Checks.Ch06.Db
  alias Course.Ch06.Post
  alias Koans.Hidden
  alias Review.Ch06.Transfer
  alias Support.Repo

  @impl true
  def cases do
    [
      {:twin, "an author hands a post to another user",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, {:new_owner, :new_owner}} = Hidden.isolated(&hand_over/0)
       end},
      {:exploit, "a missing post is not reported as :not_found",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, {:error, :not_found}} = Hidden.isolated(&missing/0)
       end},
      {:exploit, "someone who did not write a post gives it away",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, {{:error, :not_found}, :author}} = Hidden.isolated(&not_yours/0)
       end}
    ]
  end

  defp hand_over do
    ada = Db.user!("ada")
    bob = Db.user!("bob")
    post = Db.post!(ada, "gift")
    {:ok, moved} = Transfer.move_post(ada, Integer.to_string(post.id), bob.id)
    {owner(moved, ada, bob), owner(Repo.get!(Post, post.id), ada, bob)}
  end

  defp not_yours do
    ada = Db.user!("ada")
    bob = Db.user!("bob")
    post = Db.post!(ada, "gift")
    {Transfer.move_post(bob, post.id, bob.id), owner(Repo.get!(Post, post.id), ada, bob)}
  end

  defp missing do
    ada = Db.user!("ada")
    Transfer.move_post(ada, 999_999, Db.user!("bob").id)
  end

  defp owner(%Post{user_id: id}, %{id: id}, _new_owner), do: :author
  defp owner(%Post{user_id: id}, _author, %{id: id}), do: :new_owner
end
