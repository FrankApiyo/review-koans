defmodule Checks.Ch07.QuietLive do
  use Koans.Checks, review: Review.Ch07.QuietLive

  import Phoenix.LiveViewTest

  alias Checks.Ch07.Live
  alias Review.Ch07.QuietLive

  @impl true
  def cases do
    [
      {:twin, "the header counts the signed-in user's items",
       fn -> assert {:ok, "3"} = as_ada(fn {_view, html} -> Live.text(html, "#count") end) end},
      {:exploit, "a message the view has no clause for leaves it running",
       fn -> assert {:ok, "3"} = as_ada(&stray_message/1) end}
    ]
  end

  defp as_ada(interact) do
    Live.check(fn -> [Live.open(QuietLive, Live.ada())] end, fn [page] -> interact.(page) end)
  end

  # The view takes messages from one sender in order, so it has dealt with the stray message
  # before it answers :sys.get_state/1, or it has stopped.
  defp stray_message({view, _html}) do
    send(view.pid, {:refresh, :all})
    _state = :sys.get_state(view.pid)
    view |> render() |> Live.text("#count")
  end
end
