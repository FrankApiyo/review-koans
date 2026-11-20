defmodule Checks.Ch07.PickerLive do
  use Koans.Checks, review: Review.Ch07.PickerLive

  import Phoenix.LiveViewTest

  alias Checks.Ch07.Live
  alias Review.Ch07.PickerLive

  @impl true
  def cases do
    [
      {:twin, "clicking an item's pick button keeps the user's items listed",
       fn -> assert {:ok, ["item-1", "item-3", "item-4"]} = as_ada(&rows_after_click/1) end},
      {:twin, "a pick that names another user's item shows none of theirs",
       fn -> assert {:ok, :not_shown} = as_ada(&pick_bobs_item/1) end},
      {:exploit, "clicking an item's pick button shows its title",
       fn -> assert {:ok, "apple"} = as_ada(&click_apple/1) end}
    ]
  end

  defp as_ada(interact) do
    Live.check(fn -> [Live.open(PickerLive, Live.ada())] end, fn [{view, _}] ->
      interact.(view)
    end)
  end

  defp rows_after_click(view) do
    view |> element("#item-3 button") |> render_click() |> Live.rows()
  end

  defp pick_bobs_item(view) do
    case Live.attempt(fn -> render_click(view, "pick", %{"id" => "2"}) end) do
      html when is_binary(html) -> shown(Live.text(html, "#picked"))
      stopped -> shown(stopped)
    end
  end

  defp shown("Bob's plan"), do: :shown
  defp shown(_none_or_stopped), do: :not_shown

  defp click_apple(view) do
    view |> element("#item-3 button") |> render_click() |> Live.text("#picked")
  end
end
