defmodule Checks.Ch07.SortLive do
  use Koans.Checks, review: Review.Ch07.SortLive

  import Phoenix.LiveViewTest

  alias Checks.Ch07.Live
  alias Review.Ch07.SortLive

  @impl true
  def cases do
    [
      {:twin, "sorting by title puts apple first",
       fn -> assert {:ok, ["apple", "bread", "tea"]} = as_ada(&by_title/1) end},
      {:exploit, "a client asks to sort by a column name it made up",
       fn -> assert {:ok, {:no_atom, ["apple", "bread", "tea"]}} = as_ada(&made_up_column/1) end}
    ]
  end

  defp as_ada(interact) do
    Live.check(fn -> [Live.open(SortLive, Live.ada())] end, fn [{view, _}] -> interact.(view) end)
  end

  defp by_title(view), do: view |> element("button", "title") |> render_click() |> Live.titles()

  # A name unique to this run, so no earlier run or batched koan can have made it an atom.
  defp made_up_column(view) do
    column = "sort_by_#{System.unique_integer([:positive])}"
    _html = render_click(view, "sort", %{"by" => column})
    {atom_made(column), view |> render() |> Live.titles() |> Enum.sort()}
  end

  defp atom_made(name) do
    String.to_existing_atom(name)
    :atom_made
  rescue
    ArgumentError -> :no_atom
  end
end
