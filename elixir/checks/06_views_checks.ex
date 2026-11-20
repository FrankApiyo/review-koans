defmodule Checks.Ch06.Views do
  use Koans.Checks, review: Review.Ch06.Views

  alias Checks.Ch06.Db
  alias Course.Ch06.Post
  alias Koans.Hidden
  alias Review.Ch06.Views
  alias Support.Repo

  @impl true
  def cases do
    [
      {:twin, "one page load counts one view",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, 1} = Hidden.isolated(&one_load/0)
       end},
      {:exploit, "two page loads of the same post count one view",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, 2} = Hidden.isolated(&two_tabs/0)
       end},
      {:exploit, "a view reads the count, then writes it in a second query",
       fn ->
         :ok = Support.Db.reset!()
         post = Db.post!(Db.user!("ada"), "hot")

         assert {{:ok, :ok}, [<<"UPDATE ", _::binary>>]} =
                  Db.queries_during(fn -> Views.bump(post) end)
       end}
    ]
  end

  defp one_load do
    post = Db.post!(Db.user!("ada"), "hot")
    :ok = Views.bump(Repo.get!(Post, post.id))
    Repo.get!(Post, post.id).views
  end

  # Two tabs load the post before either counts its view; no concurrency is needed.
  defp two_tabs do
    post = Db.post!(Db.user!("ada"), "hot")
    tab_a = Repo.get!(Post, post.id)
    tab_b = Repo.get!(Post, post.id)
    :ok = Views.bump(tab_a)
    :ok = Views.bump(tab_b)
    Repo.get!(Post, post.id).views
  end
end
