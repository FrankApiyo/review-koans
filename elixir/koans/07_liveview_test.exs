defmodule Koans.Ch07.LiveViewTest do
  @moduledoc ~S"""
  Look for: a `handle_event` that acts on an id without asking whose it is; a `phx-value-*`
  compared with an integer; `String.to_atom` on anything a client sent; one PubSub topic for
  every user's private items; and URL state read in `mount` but not in `handle_params`.

  Why it bites: a client can send any event with any value, as `render_click/3` does here, so
  hiding a button guards nothing. Someone deletes another user's note; a pick never shows,
  because `"2" == 2` is false; the node stops when its atom table fills, since atoms are never
  garbage collected; a private item appears in someone else's feed.

  Review habit: Ask who supplied the value. Params, `phx-value-*` values and the URL come from
  the client; a `phx-value-*` attribute is text, so it arrives as a string. LiveView documents
  that `mount/3` runs twice, for the plain HTTP render and again once the socket connects
  (`connected?/1` tells them apart), that a routed view's `handle_params/3` runs after `mount`
  and on every patch, and that `push_patch` keeps the process, `push_navigate` mounts a new one
  and `redirect` reloads the page. So authorise in the handler against the session's user, and
  answer "not yours" as you answer "not there"; map column names through an allow-list; read
  URL state in `handle_params`; broadcast private data on a per-user topic, since PubSub
  delivers every message on a topic to each subscriber. A forged or malformed value may stop
  the forger's own view, so this course accepts `String.to_integer`, `String.to_existing_atom`
  and guards with no fallback clause; it asks that no other user's data is shown or changed and
  no atom is made. A LiveView with no `handle_info/2` logs a stray message at debug level and
  carries on: that is LiveView's choice. A `handle_info` with no catch-all crashes on it.

  A common mistake: dropping other users' items in `handle_info`. The checks pass, but each
  private item still reaches every subscriber's process.

  Read more: https://hexdocs.pm/phoenix_live_view/1.1.33/Phoenix.LiveView.html,
  https://hexdocs.pm/phoenix_live_view/1.1.33/security-model.html,
  https://hexdocs.pm/phoenix_pubsub/2.4.1/Phoenix.PubSub.html
  """
  use Koans

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Course.Ch07.{MenuLive, Store}

  @endpoint Support.Endpoint

  koan "Ada (user 1) opens /ch07/dashboard?tag=food: a plain GET renders it, then live/2 connects. What do #mode, #count and #tag read in each render?" do
    start_supervised!(
      {Store,
       [
         %{id: 1, title: "tea", user_id: 1, tag: "drink"},
         %{id: 2, title: "apple", user_id: 1, tag: "food"},
         %{id: 3, title: "Bob's plan", user_id: 2, tag: "food"}
       ]}
    )

    conn = Support.Live.conn(1)
    static = conn |> get("/ch07/dashboard?tag=food") |> html_response(200)
    {:ok, _view, connected} = live(conn, "/ch07/dashboard?tag=food")

    assert texts(static, ["#mode", "#count", "#tag"]) == __
    assert texts(connected, ["#mode", "#count", "#tag"]) == __
  end

  koan "Each menu button is <button phx-click=\"pick\" phx-value-id={drink.id}>, and coffee's id is the integer 2. Ada clicks coffee: which params reach handle_event, and what does #picked read?" do
    {:ok, view, _html} = live_isolated(build_conn(), MenuLive, session: %{"observer" => self()})
    html = view |> element("button", "coffee") |> render_click()
    params = receive do: ({:params, params} -> params)

    assert params["id"] == __
    assert texts(html, ["#picked"]) == __
  end

  koan "Read traces/07_checkout_crash.exs.trace: a shopper clicks pay. Which exception stopped the LiveView, which course line raised it, and which event was it handling?" do
    assert Koans.Trace.exception("07_checkout_crash") == __
    assert Koans.Trace.first_frame("07_checkout_crash") == __
    assert Koans.Trace.event("07_checkout_crash") == __
  end

  koan "Read koans/review/07_items_live.ex. Write :fine, or the line number of the bug." do
    verdict("07_items_live.ex", __, "3b360c7f4d,60b9c1cb4f,f5b51c0ab8", "1e46f12773")
  end

  koan "Fix the bug in koans/review/07_items_live.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch07.ItemsLive, Review.Ch07.ItemsLive)
  end

  koan "Read koans/review/07_picker_live.ex. Write :fine, or the line number of the bug." do
    verdict("07_picker_live.ex", __, "4e70b858c2,7e28cd24a4,b95662ba60", "a18f7bcaeb")
  end

  koan "Fix the bug in koans/review/07_picker_live.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch07.PickerLive, Review.Ch07.PickerLive)
  end

  koan "Read koans/review/07_feed_live.ex. Write :fine, or the line number of the bug." do
    verdict("07_feed_live.ex", __, "217f1f32f1,98dcfb95c7", "1a48910e74")
  end

  koan "Fix the bug in koans/review/07_feed_live.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch07.FeedLive, Review.Ch07.FeedLive)
  end

  koan "Read koans/review/07_sort_live.ex. Write :fine, or the line number of the bug." do
    verdict("07_sort_live.ex", __, "7d1a1da39a,e1045ad552", "c4e97126c1")
  end

  koan "Fix the bug in koans/review/07_sort_live.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch07.SortLive, Review.Ch07.SortLive)
  end

  koan "Read koans/review/07_archive_live.ex. Write :fine, or the line number of the bug." do
    verdict("07_archive_live.ex", __, "e94ccadc0e", "9f16844b61")
    run_checks(Checks.Ch07.ArchiveLive, Review.Ch07.ArchiveLive)
  end

  koan "Read koans/review/07_notes_live.ex. Write :fine, or the line number of the bug." do
    verdict("07_notes_live.ex", __, "0b4bdbf955,61ad943e25,6a2ad4281d,8d59907ba2,ba01115ab3,e5ab8e67de,eb7a42b82c,f41b4be2b4", "e580515d6f")
  end

  koan "Fix the bug in koans/review/07_notes_live.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch07.NotesLive, Review.Ch07.NotesLive)
  end

  koan "Read koans/review/07_quiet_live.ex. Write :fine, or the line number of the bug." do
    verdict("07_quiet_live.ex", __, "af61ae0407", "64cd310816")
    run_checks(Checks.Ch07.QuietLive, Review.Ch07.QuietLive)
  end

  defp texts(html, selectors) do
    page = LazyHTML.from_fragment(html)
    Enum.map(selectors, &(page |> LazyHTML.query(&1) |> LazyHTML.text() |> String.trim()))
  end
end
