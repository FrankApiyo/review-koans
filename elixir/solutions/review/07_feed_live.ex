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
    PubSub.broadcast(Support.PubSub, "user:#{item.user_id}:items", {:created, item})
  end

  @impl true
  def mount(_params, %{"uid" => uid}, socket) do
    if connected?(socket), do: PubSub.subscribe(Support.PubSub, "user:#{uid}:items")
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
