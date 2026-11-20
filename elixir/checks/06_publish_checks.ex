defmodule Checks.Ch06.Publish do
  use Koans.Checks, review: Review.Ch06.Publish

  alias Checks.Ch06.Db
  alias Course.Ch06.{Comment, Post}
  alias Koans.Hidden
  alias Review.Ch06.Publish
  alias Support.Repo

  @impl true
  def cases do
    [
      {:twin, "a published post is saved with its comment and announced once",
       fn ->
         :ok = Support.Db.reset!()
         {test, ref} = {self(), make_ref()}
         assert {:ok, {:ok, 1, 1}} = Hidden.isolated(fn -> publish(test, ref, "first!") end)
         assert [1] = announced(ref)
       end},
      {:exploit, "a publish that rolls back is announced",
       fn ->
         :ok = Support.Db.reset!()
         {test, ref} = {self(), make_ref()}
         assert {:ok, {:error, 0, 0}} = Hidden.isolated(fn -> publish(test, ref, nil) end)
         assert [] = announced(ref)
       end}
    ]
  end

  defp publish(test, ref, first_comment) do
    ada = Db.user!("ada")
    notify = fn post -> send(test, {:announced, ref, post}) && :ok end
    attrs = %{"title" => "hi", "first_comment" => first_comment}
    result = outcome(Publish.publish(ada, attrs, notify))
    {result, Repo.aggregate(Post, :count), Repo.aggregate(Comment, :count)}
  end

  defp outcome({:ok, %Post{title: "hi"}}), do: :ok
  defp outcome({:error, _reason}), do: :error

  # The isolated process sends each announcement before it exits, so every one is in the
  # mailbox once its :DOWN has arrived.
  defp announced(ref) do
    {:messages, messages} = Process.info(self(), :messages)
    for {:announced, ^ref, post} <- messages, do: post_id(post)
  end

  defp post_id(%Post{id: id}), do: id
  defp post_id({:ok, %Post{id: id}}), do: id
  defp post_id(other), do: other
end
