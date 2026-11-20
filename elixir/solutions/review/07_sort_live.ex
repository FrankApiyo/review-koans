defmodule Review.Ch07.SortLive do
  @moduledoc """
  The signed-in user's items, in id order until the user sorts them with the buttons above
  the list, by title or by id.
  """

  use Phoenix.LiveView

  alias Course.Ch07.Store

  @impl true
  def mount(_params, %{"uid" => uid}, socket) do
    {:ok, assign(socket, items: Store.for_user(uid))}
  end

  @impl true
  def handle_event("sort", %{"by" => by}, socket) do
    key = Map.get(%{"title" => :title, "id" => :id}, by, :title)
    {:noreply, assign(socket, items: Enum.sort_by(socket.assigns.items, &Map.get(&1, key)))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <button phx-click="sort" phx-value-by="title">title</button>
    <button phx-click="sort" phx-value-by="id">id</button>
    <ul>
      <li :for={item <- @items} id={"item-#{item.id}"}>{item.title}</li>
    </ul>
    """
  end
end
