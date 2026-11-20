defmodule Checks.Ch08.Pagination do
  use Koans.Checks, review: Review.Ch08.Pagination

  alias Checks.Ch08.Db
  alias Koans.Hidden
  alias Review.Ch08.Pagination

  @earlier ~U[2026-01-01 09:00:00Z]
  @later ~U[2026-01-01 10:00:00Z]
  @max_pages 6

  @impl true
  def cases do
    [
      {:twin, "pages of two list each of the user's notes once, newest first",
       fn ->
         :ok = Support.Db.reset!()

         saved = [
           {"a", ~U[2026-01-01 09:00:02Z]},
           {"b", ~U[2026-01-01 09:00:04Z]},
           {"c", ~U[2026-01-01 09:00:00Z]},
           {"d", ~U[2026-01-01 09:00:03Z]},
           {"e", ~U[2026-01-01 09:00:01Z]}
         ]

         assert {:ok, ["b", "d", "a", "e", "c"]} = Hidden.isolated(fn -> titles(saved) end)
       end},
      {:exploit,
       "notes saved in the same second as a page's last note are skipped or listed again",
       fn ->
         :ok = Support.Db.reset!()
         saved = [{"a", @earlier}, {"b", @later}, {"c", @later}, {"d", @later}, {"e", @earlier}]
         assert {:ok, ["d", "c", "b", "e", "a"]} = Hidden.isolated(fn -> titles(saved) end)
       end}
    ]
  end

  # Ada's notes are inserted in list order, so ids follow it, not updated_at. Bob's newer note
  # is never hers.
  defp titles(saved) do
    ada = Db.scope!("ada")
    bob = Db.scope!("bob")
    work = Db.notebook!(ada, "work")
    Enum.each(saved, fn {title, at} -> Db.note!(work, title, at: at) end)
    Db.note!(Db.notebook!(bob, "home"), "Bob's", at: ~U[2026-01-02 09:00:00Z])
    ada |> pages(nil, @max_pages) |> Enum.map(& &1.title)
  end

  # A fix that repeats a page forever is cut off after @max_pages pages.
  defp pages(_scope, _cursor, 0), do: []

  defp pages(scope, cursor, left) do
    case Pagination.page(scope, cursor, 2) do
      [] -> []
      notes -> notes ++ pages(scope, next_cursor(notes), left - 1)
    end
  end

  defp next_cursor(notes) do
    last = List.last(notes)
    {last.updated_at, last.id}
  end
end
