defmodule Checks.Ch08.Search do
  use Koans.Checks, review: Review.Ch08.Search

  alias Checks.Ch08.Db
  alias Koans.Hidden
  alias Review.Ch08.Search

  @impl true
  def cases do
    [
      {:twin, "a word finds the user's notes that hold it, and blank text finds nothing",
       fn ->
         :ok = Support.Db.reset!()

         assert {:ok, [[~s(the "draft" plan)], []]} =
                  Hidden.isolated(fn -> find(["plan", "  "]) end)
       end},
      {:twin, "two words find the notes that hold both, in either order",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, [[~s(the "draft" plan)]]} = Hidden.isolated(fn -> find(["plan draft"]) end)
       end},
      {:exploit, "a typed word is read as search syntax, not as a word to find",
       fn ->
         :ok = Support.Db.reset!()
         searches = ["body:first", "plan NOT", "NOT", "pl*"]
         assert {:ok, [[], [], [], []]} = Hidden.isolated(fn -> find(searches) end)
       end},
      {:exploit, "a word typed with a quote does not find the notes that hold the word",
       fn ->
         :ok = Support.Db.reset!()
         searches = [~s(plan"), ~s("draft"), ~s(")]
         found = [[~s(the "draft" plan)], ["draft notes", ~s(the "draft" plan)], []]
         assert {:ok, ^found} = Hidden.isolated(fn -> find(searches) end)
       end}
    ]
  end

  # Ada's notes: `the "draft" plan`, and "draft notes" with the body "first", saved a day later.
  # Bob's note "plan B" holds "plan" too.
  defp find(searches) do
    ada = Db.scope!("ada")
    bob = Db.scope!("bob")
    work = Db.notebook!(ada, "work")
    Db.note!(work, ~s(the "draft" plan), at: ~U[2026-01-01 09:00:00Z])
    Db.note!(work, "draft notes", at: ~U[2026-01-02 09:00:00Z], body: "first")
    Db.note!(Db.notebook!(bob, "home"), "plan B")
    Enum.map(searches, fn text -> Enum.map(Search.search(ada, text), & &1.title) end)
  end
end
