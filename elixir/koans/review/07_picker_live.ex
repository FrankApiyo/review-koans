defmodule Review.Ch07.PickerLive do
  @moduledoc """
  The signed-in user's items. Clicking an item's button picks it, and its title shows below
  the list.
  """

  use Phoenix.LiveView

  alias Course.Ch07.Store

  @impl true
  def mount(_params, %{"uid" => uid}, socket) do
    {:ok, assign(socket, items: Store.for_user(uid), picked: nil)}
  end

  @impl true
  def handle_event("pick", %{"id" => id}, socket) do
    {:noreply, assign(socket, picked: Enum.find(socket.assigns.items, &(&1.id == id)))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <ul>
      <li :for={item <- @items} id={"item-#{item.id}"}>
        {item.title} <button phx-click="pick" phx-value-id={item.id}>pick</button>
      </li>
    </ul>
    <p id="picked">{if @picked, do: @picked.title, else: "none"}</p>
    """
  end
end
