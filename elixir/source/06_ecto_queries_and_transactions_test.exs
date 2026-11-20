defmodule Koans.Ch06.EctoQueriesAndTransactionsTest do
  @moduledoc ~S"""
  Look for: a `get!` or query that takes an id but not the signed-in user; a `cast` that
  permits `user_id`; SQL built by interpolating a string; a notification sent inside
  `Repo.transact`; `Repo.preload` called once per row; and a count written back from a struct
  loaded earlier.

  Why it bites: anyone who edits the id in a URL reads someone else's post. A "welcome" email
  goes out for a signup that rolled back. A profile page runs 501 queries. Two tabs count one
  view.

  Review habit: Ask who supplied the value. Ids, form params and search text come from the
  client. Scope the query by the session's user, so "not yours" raises the same
  `Ecto.NoResultsError` as "not there" (`get!`, `get_by!` and `one!` raise it; `get` and `one`
  return `nil`), and `cast` only the fields a user may set. Pass values as parameters: Ecto
  sends each `^` value apart from the SQL text, `Repo.query!/2` takes `?` on SQLite and `$1`
  on Postgres, and Ecto rejects an interpolated string as `fragment`'s SQL at compile time.
  `Repo.transact/2`, Ecto's choice since 3.13, commits on `{:ok, _}` and rolls back on
  `{:error, _}`; the soft-deprecated `transaction/2` commits whatever the function returns. A
  Multi checks the changesets it was given before the transaction starts. `update_all` and
  `insert_all` take no changeset and fill no timestamps, so a NOT NULL timestamp fails with the
  driver's error (`Exqlite.Error` here, `Postgrex.Error` on Postgres); `update_all` with `inc:`
  is one `UPDATE`. A unique index raises `Ecto.ConstraintError` unless the changeset declares
  `unique_constraint/3` under the index's name: Postgres reports that name, while ecto_sqlite3
  builds it from the table and columns SQLite reports.

  A common mistake: notifying as the transaction's last step. The commit can still fail, so
  notify once `Repo.transact` has returned `{:ok, _}`. And a preload through an inner `join:`
  drops posts that have no comments; `left_join:` keeps them.

  Read more: https://hexdocs.pm/ecto/3.14.3/Ecto.Repo.html,
  https://hexdocs.pm/ecto/3.14.3/Ecto.Query.html, https://hexdocs.pm/ecto/3.14.3/Ecto.Multi.html
  """
  use Koans

  import Ecto.Query

  alias Course.Ch06.{Post, User}
  alias Ecto.Multi
  alias Support.Repo

  koan "A Multi inserts two posts, and the second has no title. What does Repo.transact return: the failed step, the validation that failed on :title, and the changes so far? How many posts are saved?" do
    :ok = Support.Db.reset!()
    ada = Repo.insert!(%User{email: "ada@example.com"})

    result =
      Multi.new()
      |> Multi.insert(:post, Post.changeset(%Post{user_id: ada.id}, %{title: "ok"}))
      |> Multi.insert(:second, Post.changeset(%Post{user_id: ada.id}, %{title: nil}))
      |> Repo.transact()

    {:error, step, changeset, changes} = result
    [title: {_message, [validation: validation]}] = changeset.errors
    assert step == _a(:second)
    assert validation == _a(:required)
    assert changes == _a(%{})
    assert Repo.aggregate(Post, :count) == _a(0)
  end

  koan "A function inserts a draft, then returns {:error, :quota_exceeded}. What do Repo.transact and the soft-deprecated Repo.transaction each return for it, and how many drafts are saved after each?" do
    :ok = Support.Db.reset!()
    ada = Repo.insert!(%User{email: "ada@example.com"})

    save_draft = fn ->
      Repo.insert!(Post.changeset(%Post{user_id: ada.id}, %{title: "draft"}))
      {:error, :quota_exceeded}
    end

    assert Repo.transact(save_draft) == _a({:error, :quota_exceeded})
    assert Repo.aggregate(Post, :count) == _a(0)
    assert Repo.transaction(save_draft) == _a({:ok, {:error, :quota_exceeded}})
    assert Repo.aggregate(Post, :count) == _a(1)
  end

  koan "update_all renames a post last updated on 2026-01-01, then insert_all adds a post with no timestamps. What does update_all return, is updated_at still the old value, and which exception module does insert_all raise on SQLite?" do
    :ok = Support.Db.reset!()
    ada = Repo.insert!(%User{email: "ada@example.com"})
    old = ~U[2026-01-01 00:00:00Z]
    post = Repo.insert!(%Post{user_id: ada.id, title: "hello", inserted_at: old, updated_at: old})

    assert Repo.update_all(where(Post, id: ^post.id), set: [title: "renamed"]) == _a({1, nil})
    renamed = Repo.get!(Post, post.id)
    unchanged = renamed.title == "renamed" and renamed.updated_at == old
    assert unchanged == _a(true)

    bulk = fn -> Repo.insert_all(Post, [%{title: "bulk", user_id: ada.id}]) end
    assert raised(bulk) == _a(Exqlite.Error)
  end

  koan "Read traces/06_get_post.exs.trace: Bob opens Ada's post. Which exception stopped the reader, and which course line is the first frame in the trace (nil if it shows none)? get_post! ends by calling Repo.one!, and a call in last position replaces its caller's frame." do
    assert Koans.Trace.exception("06_get_post") == _a("Ecto.NoResultsError")
    assert Koans.Trace.first_frame("06_get_post") == _a(nil)
  end

  koan "Read traces/06_signup.exs.trace: Ada signs up a second time. Which exception stopped the signup, and which course line is the first frame in the trace?" do
    assert Koans.Trace.exception("06_signup") == _a("Ecto.ConstraintError")
    assert Koans.Trace.first_frame("06_signup") == _a({"traces/06_signup.exs", 10})
  end

  koan "Read koans/review/06_posts.ex. Write :fine, or the line number of the bug." do
    verdict("06_posts.ex", _a(11))
  end

  koan "Fix the bug in koans/review/06_posts.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch06.Posts, Review.Ch06.Posts)
  end

  koan "Read koans/review/06_create_post.ex. Write :fine, or the line number of the bug." do
    verdict("06_create_post.ex", _a(14))
  end

  koan "Fix the bug in koans/review/06_create_post.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch06.CreatePost, Review.Ch06.CreatePost)
  end

  koan "Read koans/review/06_titles.ex. Write :fine, or the line number of the bug." do
    verdict("06_titles.ex", _a(11))
  end

  koan "Fix the bug in koans/review/06_titles.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch06.Titles, Review.Ch06.Titles)
  end

  koan "Read koans/review/06_publish.ex. Write :fine, or the line number of the bug." do
    verdict("06_publish.ex", _a(16))
  end

  koan "Fix the bug in koans/review/06_publish.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch06.Publish, Review.Ch06.Publish)
  end

  koan "Read koans/review/06_feed.ex. Write :fine, or the line number of the bug." do
    verdict("06_feed.ex", _a(15))
  end

  koan "Fix the bug in koans/review/06_feed.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch06.Feed, Review.Ch06.Feed)
  end

  koan "Read koans/review/06_views.ex. Write :fine, or the line number of the bug." do
    verdict("06_views.ex", _a(12))
  end

  koan "Fix the bug in koans/review/06_views.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch06.Views, Review.Ch06.Views)
  end

  koan "Read koans/review/06_transfer.ex. Write :fine, or the line number of the bug." do
    verdict("06_transfer.ex", _a(:fine))
    run_checks(Checks.Ch06.Transfer, Review.Ch06.Transfer)
  end

  defp raised(fun) do
    fun.()
    :nothing_raised
  rescue
    error -> error.__struct__
  end
end
