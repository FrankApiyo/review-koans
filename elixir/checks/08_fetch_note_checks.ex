defmodule Checks.Ch08.FetchNote do
  use Koans.Checks, review: Review.Ch08.FetchNote

  alias Checks.Ch08.Db
  alias Koans.Hidden
  alias Review.Ch08.FetchNote

  @impl true
  def cases do
    [
      {:twin, "a user opens her own note by the id in the URL",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, {:ok, "plan"}} = Hidden.isolated(&own/0)
       end},
      {:twin, "another user's note, and an id no note has, are not found",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, [:not_found, :not_found, :not_found]} = Hidden.isolated(&others/0)
       end},
      {:exploit, "an id that is not a number is not answered with :not_found",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, [:not_found, :not_found]} = Hidden.isolated(fn -> open(["abc", "1.5"]) end)
       end},
      {:exploit, "a request with no id is not answered with :not_found",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, [:not_found]} = Hidden.isolated(fn -> open([nil]) end)
       end},
      {:exploit, "an id past the 64-bit range is not answered with :not_found",
       fn ->
         :ok = Support.Db.reset!()
         ids = ["99999999999999999999", "-9223372036854775809"]
         assert {:ok, [:not_found, :not_found]} = Hidden.isolated(fn -> open(ids) end)
       end}
    ]
  end

  defp seed do
    ada = Db.scope!("ada")
    Db.note!(Db.notebook!(ada, "work"), "plan")
    ada
  end

  defp own do
    ada = seed()
    outcome(FetchNote.fetch_note(ada, "1"))
  end

  defp open(ids) do
    ada = seed()
    Enum.map(ids, &outcome(FetchNote.fetch_note(ada, &1)))
  end

  defp others do
    ada = seed()
    bob = Db.scope!("bob")

    Enum.map([{bob, "1"}, {ada, "-1"}, {ada, "0"}], fn {scope, id} ->
      outcome(FetchNote.fetch_note(scope, id))
    end)
  end

  defp outcome({:ok, %Course.Ch08.Note{title: title}}), do: {:ok, title}
  defp outcome({:error, :not_found}), do: :not_found
end
