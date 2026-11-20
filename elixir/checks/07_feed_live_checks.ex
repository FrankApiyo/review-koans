defmodule Checks.Ch07.FeedLive do
  use Koans.Checks, review: Review.Ch07.FeedLive

  import Phoenix.LiveViewTest

  alias Checks.Ch07.Live
  alias Koans.Hidden
  alias Review.Ch07.FeedLive

  @ada_secret %{id: 9, title: "Ada's secret", user_id: 1, tag: "food"}
  @bob_note %{id: 10, title: "Bob's note", user_id: 2, tag: "food"}

  @impl true
  def cases do
    [
      {:twin, "a new item shows in its owner's open feed",
       fn ->
         assert {:ok, true} =
                  Live.check(fn -> [Live.open(FeedLive, Live.ada())] end, &own_feed/1)
       end},
      {:exploit, "a new item shows in another user's open feed",
       fn ->
         assert {:ok, {true, ["Bob's plan", "Bob's note"]}} =
                  Live.check(&ada_and_bob/0, &other_feed/1)
       end}
    ]
  end

  defp ada_and_bob, do: [Live.open(FeedLive, Live.ada()), Live.open(FeedLive, Live.bob())]

  defp own_feed([{ada, _html}]) do
    :ok = FeedLive.publish(@ada_secret)
    shows?(ada, "Ada's secret")
  end

  # Phoenix.PubSub sends to local subscribers from the publishing process, so both items reach
  # Bob's view from one sender, in order: once his own note shows, Ada's secret has already
  # reached him if it was going to.
  defp other_feed([{_ada, _}, {bob, _}]) do
    :ok = FeedLive.publish(@ada_secret)
    :ok = FeedLive.publish(@bob_note)
    {shows?(bob, "Bob's note"), Live.titles(render(bob))}
  end

  defp shows?(view, title), do: Hidden.wait_until(fn -> title in Live.titles(render(view)) end)
end
