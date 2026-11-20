defmodule Checks.Ch06.CreatePost do
  use Koans.Checks, review: Review.Ch06.CreatePost

  alias Checks.Ch06.Db
  alias Course.Ch06.Post
  alias Koans.Hidden
  alias Review.Ch06.CreatePost
  alias Support.Repo

  @impl true
  def cases do
    [
      {:twin, "a post from the form is saved with its author",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, {"mine", :author, :author}} = Hidden.isolated(&from_the_form/0)
       end},
      {:exploit, "the form cannot choose the post's author",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, {"planted", :author, :author}} = Hidden.isolated(&planted_author/0)
       end}
    ]
  end

  defp from_the_form do
    ada = Db.user!("ada")
    {:ok, post} = CreatePost.create(ada, %{"title" => "mine"})
    {post.title, author(post, ada), author(Repo.get!(Post, post.id), ada)}
  end

  defp planted_author do
    ada = Db.user!("ada")
    bob = Db.user!("bob")
    attrs = %{"title" => "planted", "user_id" => Integer.to_string(bob.id)}
    {:ok, post} = CreatePost.create(ada, attrs)
    {post.title, author(post, ada), author(Repo.get!(Post, post.id), ada)}
  end

  defp author(%Post{user_id: id}, %{id: id}), do: :author
  defp author(%Post{}, _user), do: :someone_else
end
