defmodule Checks.Ch07.OwnerOnly do
  @moduledoc """
  Case bodies for a LiveView event that removes one of the signed-in user's items from their
  list, by id. Each opens the view as Ada (user 1) through `Checks.Ch07.Live.check/2`. A view
  that stops on a forged event shows nothing, which these bodies accept.
  """

  import Phoenix.LiveViewTest

  alias Checks.Ch07.Live

  @ada_rows ["item-1", "item-3", "item-4"]

  @doc "Ada clicks the button on her tea: her kept items, and the rows her page shows."
  @spec own(module()) :: {:ok, term()} | {:down, term()} | :timeout
  def own(view_module) do
    as_ada(view_module, fn view ->
      html = view |> element("#item-1 button") |> render_click()
      {Live.kept(Live.ada()), Live.rows(html)}
    end)
  end

  @doc "Ada's page sends `event` for Bob's item: Bob's kept items, and other users' rows it shows."
  @spec forged(module(), String.t()) :: {:ok, term()} | {:down, term()} | :timeout
  def forged(view_module, event) do
    as_ada(view_module, fn view ->
      page = Live.attempt(fn -> render_click(view, event, %{"id" => "2"}) end)
      {Live.kept(Live.bob()), others_shown(page)}
    end)
  end

  @doc "Two of Ada's pages: one sends `event` for Bob's item, the other for an id nobody has."
  @spec not_yours_then_missing(module(), String.t()) :: {:ok, term()} | {:down, term()} | :timeout
  def not_yours_then_missing(view_module, event) do
    two_pages = fn -> [Live.open(view_module, Live.ada()), Live.open(view_module, Live.ada())] end

    Live.check(two_pages, fn [{not_yours, _}, {missing, _}] ->
      {answer(not_yours, event, "2"), answer(missing, event, "99")}
    end)
  end

  defp answer(view, event, id) do
    case Live.attempt(fn -> render_click(view, event, %{"id" => id}) end) do
      html when is_binary(html) -> {Live.rows(html), Live.text(html, "#flash")}
      stopped -> stopped
    end
  end

  defp others_shown(:stopped), do: []
  defp others_shown(html), do: Live.rows(html) -- @ada_rows

  defp as_ada(view_module, interact) do
    Live.check(fn -> [Live.open(view_module, Live.ada())] end, fn [{view, _html}] ->
      interact.(view)
    end)
  end
end
