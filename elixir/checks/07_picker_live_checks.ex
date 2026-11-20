defmodule Checks.Ch07.PickerLive do
  use Koans.Checks, review: Review.Ch07.PickerLive

  import Phoenix.LiveViewTest

  alias Checks.Ch07.Live
  alias Review.Ch07.PickerLive

  @impl true
  def cases do
    [
      {:twin, "a pick that names none of the user's items shows none, and the view keeps running",
       fn -> assert {:ok, {"none", "none"}} = as_ada(&no_such_item/1) end},
      {:exploit, "clicking an item's pick button shows its title",
       fn -> assert {:ok, "apple"} = as_ada(&click_apple/1) end}
    ]
  end

  defp as_ada(interact) do
    Live.check(fn -> [Live.open(PickerLive, Live.ada())] end, fn [{view, _}] ->
      interact.(view)
    end)
  end

  defp no_such_item(view) do
    not_yours = render_click(view, "pick", %{"id" => "2"})
    not_a_number = render_click(view, "pick", %{"id" => "abc"})
    {Live.text(not_yours, "#picked"), Live.text(not_a_number, "#picked")}
  end

  defp click_apple(view) do
    view |> element("#item-3 button") |> render_click() |> Live.text("#picked")
  end
end
