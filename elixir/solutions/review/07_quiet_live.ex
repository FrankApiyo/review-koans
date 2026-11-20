defmodule Review.Ch07.QuietLive do
  @moduledoc """
  The signed-in user's item count, shown in the page header.
  """

  use Phoenix.LiveView

  alias Course.Ch07.Store

  @impl true
  def mount(_params, %{"uid" => uid}, socket) do
    {:ok, assign(socket, count: length(Store.for_user(uid)))}
  end

  @impl true
  def render(assigns), do: ~H|<p id="count">{@count}</p>|
end
