defmodule Koans.Ch08.QuireTest do
  @moduledoc ~S"""
  Look for: what each function leaves out. The code is shaped like Quire, the notes app from the
  phoenix-koans course: an id used without `Id.cast`, search text sent to FTS5 as typed, a page
  cursor with no tiebreak, an upsert's returned rows taken as every row, a broadcast that
  ignores the result, and a form save that checks no version.

  Why it bites: `Ecto.Type.cast(:id, _)` accepts any integer, but SQLite integers are 64-bit, so
  a longer id from a URL raises in the driver. In an FTS5 query a `"` ends a phrase, and `NOT`
  or `body:` are syntax. Notes saved in the same second share an `updated_at`, so a cursor on it
  alone skips or repeats them; an offset shifts whenever a newer note is saved. With
  `on_conflict: :nothing`, `returning` gives back only the rows inserted. A second tab's save
  overwrites the first.

  Review habit: Read for what is missing: the id's range; the owner, so every query is scoped by
  the session's user and "not yours" reads as "not there"; a tiebreak column; the rows the
  insert skipped; the `{:error, _}` branch; the version the form was rendered with. Scope PubSub
  topics by user as well, since each subscriber gets every message on its topic. ecto_sqlite3
  stores `utc_datetime` as ISO-8601 text, which is the adapter's choice, so `<` compares
  strings, and the fixed width keeps that in time order. Inside FTS5 quotes, `""` is one quote;
  dropping quotes works too, as the default tokenizer ignores them. `optimistic_lock/3` plus
  `stale_error_field:` turns a stale save into `{:error, changeset}`; without that option,
  `Repo.update` raises `Ecto.StaleEntryError`.

  A common mistake: a row-value cursor, `fragment("(?, ?) < (?, ?)", ...)`, with the timestamp
  pinned untyped. exqlite then sends it without its `Z`, so it never equals the stored text;
  write `type(^updated_at, :utc_datetime)`.

  Read more: https://hexdocs.pm/ecto/3.14.3/Ecto.Changeset.html,
  https://hexdocs.pm/ecto_sqlite3/0.26.0/Ecto.Adapters.SQLite3.html,
  https://hexdocs.pm/phoenix_pubsub/2.4.1/Phoenix.PubSub.html
  """
  use Koans

  import Ecto.Changeset

  alias Course.Ch08.{Note, Notebook, User}
  alias Support.Repo

  koan "Ecto.Type.cast(:id, value) is how Ecto casts an id that arrives as a string, such as one from a URL. What does it return for each value? Then an id past the 64-bit range reaches Repo.get_by: which exception module is raised?" do
    :ok = Support.Db.reset!()

    assert Ecto.Type.cast(:id, "007") == _a({:ok, 7})
    assert Ecto.Type.cast(:id, " 7") == _a(:error)
    assert Ecto.Type.cast(:id, "-1") == _a({:ok, -1})
    assert Ecto.Type.cast(:id, "99999999999999999999") == _a({:ok, 99_999_999_999_999_999_999})

    assert raised(fn -> Repo.get_by(Note, id: 99_999_999_999_999_999_999) end) ==
             _a(Exqlite.Error)
  end

  koan "Two tabs load the same note at lock_version 1. Each saves a new title with optimistic_lock(:lock_version) and Repo.update/1, tab A first. What does tab A's save return, which exception module does tab B's save raise, and whose title is stored?" do
    :ok = Support.Db.reset!()
    note = seed_note!()
    tab_a = Repo.get!(Note, note.id)
    tab_b = Repo.get!(Note, note.id)

    save = fn tab, title ->
      tab |> change(title: title) |> optimistic_lock(:lock_version) |> Repo.update()
    end

    {:ok, saved} = save.(tab_a, "from A")
    assert {saved.title, saved.lock_version} == _a({"from A", 2})
    assert raised(fn -> save.(tab_b, "from B") end) == _a(Ecto.StaleEntryError)
    assert Repo.get!(Note, note.id).title == _a("from A")
  end

  koan "Read traces/08_two_tabs.exs.trace: Ada has her notes open in two tabs and deletes the plan in each. Which exception stopped the second tab's LiveView, and which course line raised it? The plan was still listed in that tab: why was it gone?" do
    assert Koans.Trace.exception("08_two_tabs") == _a("MatchError")
    assert Koans.Trace.first_frame("08_two_tabs") == _a({"traces/08_two_tabs.exs", 36})
  end

  koan "Read koans/review/08_fetch_note.ex. Write :fine, or the line number of the bug." do
    verdict("08_fetch_note.ex", _a(13))
  end

  koan "Fix the bug in koans/review/08_fetch_note.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch08.FetchNote, Review.Ch08.FetchNote)
  end

  koan "Read koans/review/08_authorize.ex. Write :fine, or the line number of the bug." do
    verdict("08_authorize.ex", _a(:fine))
    run_checks(Checks.Ch08.Authorize, Review.Ch08.Authorize)
  end

  koan "Read koans/review/08_search.ex. Write :fine, or the line number of the bug." do
    verdict("08_search.ex", _a(34))
  end

  koan "Fix the bug in koans/review/08_search.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch08.Search, Review.Ch08.Search)
  end

  koan "Read koans/review/08_pagination.ex. Write :fine, or the line number of the bug." do
    verdict("08_pagination.ex", _a(26))
  end

  koan "Fix the bug in koans/review/08_pagination.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch08.Pagination, Review.Ch08.Pagination)
  end

  koan "Read koans/review/08_tags.ex. Write :fine, or the line number of the bug." do
    verdict("08_tags.ex", _a(17))
  end

  koan "Fix the bug in koans/review/08_tags.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch08.Tags, Review.Ch08.Tags)
  end

  koan "Read koans/review/08_broadcast.ex. Write :fine, or the line number of the bug." do
    verdict("08_broadcast.ex", _a(34))
  end

  koan "Fix the bug in koans/review/08_broadcast.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch08.Broadcast, Review.Ch08.Broadcast)
  end

  koan "Read koans/review/08_update_note.ex. Write :fine, or the line number of the bug." do
    verdict("08_update_note.ex", _a(19))
  end

  koan "Fix the bug in koans/review/08_update_note.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch08.UpdateNote, Review.Ch08.UpdateNote)
  end

  defp seed_note! do
    at = ~U[2026-01-01 09:00:00Z]
    ada = Repo.insert!(%User{email: "ada@example.com"})
    work = Repo.insert!(%Notebook{name: "work", user_id: ada.id, inserted_at: at, updated_at: at})

    Repo.insert!(%Note{
      title: "draft",
      notebook_id: work.id,
      user_id: ada.id,
      inserted_at: at,
      updated_at: at
    })
  end

  defp raised(fun) do
    fun.()
    :nothing_raised
  rescue
    error -> error.__struct__
  end
end
