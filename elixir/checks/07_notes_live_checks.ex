defmodule Checks.Ch07.NotesLive do
  use Koans.Checks, review: Review.Ch07.NotesLive

  import Phoenix.LiveViewTest

  alias Checks.Ch07.Live

  @impl true
  def cases do
    [
      {:twin, "a bookmarked tag URL lists only that tag's notes",
       fn -> assert {:ok, ["apple", "bread"]} = at("/ch07/notes?tag=food", &first_render/1) end},
      {:twin, "the notes page without a tag lists every note",
       fn -> assert {:ok, ["tea", "apple", "bread"]} = at("/ch07/notes", &first_render/1) end},
      {:exploit, "choosing a tag refilters the list in the same LiveView",
       fn -> assert {:ok, ["tea"]} = at("/ch07/notes?tag=food", &choose_drink/1) end},
      {:exploit, "a patch to another tag's URL, as the back button sends, refilters the list",
       fn -> assert {:ok, ["apple", "bread"]} = at("/ch07/notes?tag=drink", &back_to_food/1) end}
    ]
  end

  defp at(path, interact) do
    Live.check(fn -> [Live.visit(Live.ada(), path)] end, fn [page] -> interact.(page) end)
  end

  defp first_render({_view, html}), do: Live.titles(html)

  # The tag control may be a button or a patch link. A navigation instead of a patch returns
  # {:error, {:live_redirect, _}}, not a page.
  defp choose_drink({view, _html}) do
    case view |> element("button, a", "drink") |> render_click() do
      html when is_binary(html) -> Live.titles(html)
      navigated -> navigated
    end
  end

  defp back_to_food({view, _html}) do
    view |> render_patch("/ch07/notes?tag=food") |> Live.titles()
  end
end
