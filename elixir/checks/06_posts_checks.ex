defmodule Checks.Ch06.Posts do
  use Koans.Checks, review: Review.Ch06.Posts

  alias Checks.Ch06.Db
  alias Koans.Hidden
  alias Review.Ch06.Posts

  @impl true
  def cases do
    [
      {:twin, "an author reads their own post",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, "Ada's draft"} = Hidden.isolated(&own_post/0)
       end},
      {:twin, "an id taken from the URL, as a string, reads the post",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, "Ada's draft"} = Hidden.isolated(&own_post_from_url/0)
       end},
      {:exploit, "someone else's post raises what a missing post raises",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, {Ecto.NoResultsError, Ecto.NoResultsError}} = Hidden.isolated(&not_yours/0)
       end}
    ]
  end

  defp own_post do
    ada = Db.user!("ada")
    post = Db.post!(ada, "Ada's draft")
    Posts.get_post!(ada, post.id).title
  end

  defp own_post_from_url do
    ada = Db.user!("ada")
    post = Db.post!(ada, "Ada's draft")
    Posts.get_post!(ada, Integer.to_string(post.id)).title
  end

  defp not_yours do
    ada = Db.user!("ada")
    bob = Db.user!("bob")
    post = Db.post!(ada, "Ada's draft")

    {Db.raised(fn -> Posts.get_post!(bob, post.id) end),
     Db.raised(fn -> Posts.get_post!(bob, 999_999) end)}
  end
end
