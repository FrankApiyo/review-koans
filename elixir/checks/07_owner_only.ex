defmodule Checks.Ch07.OwnerOnly do
  @moduledoc """
  Case bodies for a LiveView event that removes one of the signed-in user's items from their
  list, by id. Each opens the view as Ada (user 1) through `Checks.Ch07.Live.check/2`.
  """

  import Phoenix.LiveViewTest

  alias Checks.Ch07.Live

  @doc "Ada clicks the button on her tea: her kept items, and the rows her page shows."
  @spec own(module()) :: {:ok, term()} | {:down, term()} | :timeout
  def own(view_module) do
    as_ada(view_module, fn view ->
      html = view |> element("#item-1 button") |> render_click()
      {Live.kept(Live.ada()), Live.rows(html)}
    end)
  end

  @doc "Ada's page sends `event` for Bob's item: Bob's kept items, and the rows her page shows."
  @spec forged(module(), String.t()) :: {:ok, term()} | {:down, term()} | :timeout
  def forged(view_module, event) do
    as_ada(view_module, fn view ->
      _html = render_click(view, event, %{"id" => "2"})
      {Live.kept(Live.bob()), Live.rows(render(view))}
    end)
  end

  @doc "The page after `event` for Bob's item, then after `event` for an id nobody has."
  @spec not_yours_then_missing(module(), String.t()) :: {:ok, term()} | {:down, term()} | :timeout
  def not_yours_then_missing(view_module, event) do
    as_ada(view_module, fn view ->
      not_yours = render_click(view, event, %{"id" => "2"})
      missing = render_click(view, event, %{"id" => "99"})
      {not_yours, missing}
    end)
  end

  @doc "Ada's page sends `event` with an id that is not a number: the rows it shows next."
  @spec malformed(module(), String.t()) :: {:ok, term()} | {:down, term()} | :timeout
  def malformed(view_module, event) do
    as_ada(view_module, fn view ->
      _html = render_click(view, event, %{"id" => "abc"})
      Live.rows(render(view))
    end)
  end

  defp as_ada(view_module, interact) do
    Live.check(fn -> [Live.open(view_module, Live.ada())] end, fn [{view, _html}] ->
      interact.(view)
    end)
  end
end
