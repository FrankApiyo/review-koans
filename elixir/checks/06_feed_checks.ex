defmodule Checks.Ch06.Feed do
  use Koans.Checks, review: Review.Ch06.Feed

  alias Checks.Ch06.Db
  alias Review.Ch06.Feed

  @impl true
  def cases do
    [
      {:twin, "every post is listed with its comments, one with none included",
       fn ->
         :ok = Support.Db.reset!()
         ada = seed()
         assert {{:ok, posts}, _queries} = Db.queries_during(fn -> Feed.with_comments(ada) end)
         assert ["p1", "p2", "p3", "p4", "p5"] = Enum.map(posts, & &1.title)
         assert [1, 1, 0, 1, 1] = Enum.map(posts, &length(&1.comments))
       end},
      {:exploit, "comments load with one query per post",
       fn ->
         :ok = Support.Db.reset!()
         ada = seed()
         assert {{:ok, _posts}, queries} = Db.queries_during(fn -> Feed.with_comments(ada) end)
         assert length(queries) <= 2
       end}
    ]
  end

  defp seed do
    ada = Db.user!("ada")
    bob = Db.user!("bob")
    _ = Db.comment!(Db.post!(bob, "bob's"), "not ada's")

    for n <- 1..5 do
      post = Db.post!(ada, "p#{n}")
      if n != 3, do: Db.comment!(post, "c#{n}")
    end

    ada
  end
end
