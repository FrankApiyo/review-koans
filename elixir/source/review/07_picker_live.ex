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
  # >>> fix
  def handle_event("pick", %{"id" => id}, socket) do
    {:noreply, assign(socket, picked: Enum.find(socket.assigns.items, &(&1.id == id)))}
  end
  # === fixed
  def handle_event("pick", %{"id" => id}, socket) do
    picked =
      case Integer.parse(id) do
        {id, ""} -> Enum.find(socket.assigns.items, &(&1.id == id))
        _not_a_number -> nil
      end

    {:noreply, assign(socket, picked: picked)}
  end
  # === alt: compares the item's id as text with the id the client sent
  def handle_event("pick", %{"id" => id}, socket) do
    picked = Enum.find(socket.assigns.items, &(Integer.to_string(&1.id) == id))
    {:noreply, assign(socket, picked: picked)}
  end
  # === wrong: refuses — rejects every pick by raising, which stops the view
  def handle_event("pick", _params, _socket), do: raise(ArgumentError, "picking is off")
  # === wrong: partial — String.to_integer raises on an id that is not a number, which stops the view
  def handle_event("pick", %{"id" => id}, socket) do
    id = String.to_integer(id)
    {:noreply, assign(socket, picked: Enum.find(socket.assigns.items, &(&1.id == id)))}
  end
  # === wrong: partial — looks the id up in the store, so it picks another user's item
  def handle_event("pick", %{"id" => id}, socket) do
    picked =
      case Integer.parse(id) do
        {id, ""} -> Store.get(id)
        _not_a_number -> nil
      end

    {:noreply, assign(socket, picked: picked)}
  end
  # <<<

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
