defmodule Checks.Ch06.Titles do
  use Koans.Checks, review: Review.Ch06.Titles

  alias Checks.Ch06.Db
  alias Koans.Hidden
  alias Review.Ch06.Titles

  @impl true
  def cases do
    [
      {:twin, "a plain title finds its post",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, [1]} = Hidden.isolated(fn -> search("Hello") end)
       end},
      {:exploit, "quotes in the search change the query",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, []} = Hidden.isolated(fn -> search("x' OR '1'='1") end)
       end},
      {:exploit, "a title with apostrophes cannot be found",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, [2]} = Hidden.isolated(fn -> search("O'Brien's notes") end)
       end},
      {:exploit, "a search holding a NUL byte crashes the query",
       fn ->
         :ok = Support.Db.reset!()
         assert {:ok, ids} = Hidden.isolated(fn -> search("Hello\0") end)
         assert is_list(ids)
       end}
    ]
  end

  defp search(title) do
    ada = Db.user!("ada")
    Enum.each(["Hello", "O'Brien's notes", "Other"], &Db.post!(ada, &1))
    Titles.ids_titled(title)
  end
end
