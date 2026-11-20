defmodule Course.Ch07.DashboardLive do
  @moduledoc """
  The signed-in user's dashboard at `/ch07/dashboard`. It loads the user's items once the
  socket is connected, and shows the tag from the URL.
  """

  use Phoenix.LiveView

  alias Course.Ch07.Store

  @impl true
  def mount(_params, %{"uid" => uid}, socket) do
    items = if connected?(socket), do: Store.for_user(uid), else: []
    {:ok, assign(socket, items: items)}
  end

  @impl true
  def handle_params(params, _uri, socket), do: {:noreply, assign(socket, tag: params["tag"])}

  @impl true
  def render(assigns) do
    ~H"""
    <p id="mode">{if connected?(@socket), do: "live", else: "static"}</p>
    <p id="count">{length(@items)}</p>
    <p id="tag">{@tag}</p>
    """
  end
end
