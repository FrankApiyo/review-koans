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

  # >>> guard
  @impl true
  def render(assigns), do: ~H|<p id="count">{@count}</p>|
  # === wrong: partial — handles only the message it expects, with no catch-all, so any other message stops the view
  @impl true
  def handle_info({:count, count}, socket), do: {:noreply, assign(socket, count: count)}

  @impl true
  def render(assigns), do: ~H|<p id="count">{@count}</p>|
  # <<<
end
