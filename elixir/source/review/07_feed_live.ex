defmodule Review.Ch07.FeedLive do
  @moduledoc """
  A live feed of the signed-in user's items. `publish/1` announces a new item, and every feed
  its owner has open shows it at once. A user's items are private to that user.
  """

  use Phoenix.LiveView

  alias Course.Ch07.Store
  alias Phoenix.PubSub

  @spec publish(map()) :: :ok | {:error, term()}
  def publish(item) do
    # >>> fix
    PubSub.broadcast(Support.PubSub, "items", {:created, item})
    # === fixed
    PubSub.broadcast(Support.PubSub, "user:#{item.user_id}:items", {:created, item})
    # === wrong: refuses — announces nothing
    _ = item
    :ok
    # === wrong: partial — local_broadcast stays on this node, but every feed on it still gets the item
    PubSub.local_broadcast(Support.PubSub, "items", {:created, item})
    # <<<
  end

  @impl true
  def mount(_params, %{"uid" => uid}, socket) do
    # >>> fix
    if connected?(socket), do: PubSub.subscribe(Support.PubSub, "items")
    # === fixed
    if connected?(socket), do: PubSub.subscribe(Support.PubSub, "user:#{uid}:items")
    # === wrong: refuses — subscribes to nothing
    _ = connected?(socket)
    # === wrong: partial — subscribes during the disconnected render, whose process ends once the page is sent
    unless connected?(socket), do: PubSub.subscribe(Support.PubSub, "user:#{uid}:items")
    # <<<
    {:ok, assign(socket, items: Store.for_user(uid))}
  end

  @impl true
  def handle_info({:created, item}, socket) do
    {:noreply, assign(socket, items: socket.assigns.items ++ [item])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <ul>
      <li :for={item <- @items} id={"item-#{item.id}"}>{item.title}</li>
    </ul>
    """
  end
end
