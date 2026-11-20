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
    # >>> fix
    key = String.to_atom(by)
    # === fixed
    key = Map.get(%{"title" => :title, "id" => :id}, by, :title)
    # === alt: a case on the two column names
    key =
      case by do
        "id" -> :id
        _title -> :title
      end
    # === alt: String.to_existing_atom, with :title for a name no code has used
    key =
      try do
        String.to_existing_atom(by)
      rescue
        ArgumentError -> :title
      end
    # === wrong: refuses — ignores the column and keeps id order
    _ = by
    key = :id
    # === wrong: partial — String.to_existing_atom raises on a name no code has used, which stops the view
    key = String.to_existing_atom(by)
    # <<<
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
