defmodule Review.Ch07.ItemsLive do
  @moduledoc """
  The signed-in user's items, each with a delete button. The session holds the user's id as
  `"uid"`.
  """

  use Phoenix.LiveView

  alias Course.Ch07.Store

  @impl true
  def mount(_params, %{"uid" => uid}, socket) do
    {:ok, assign(socket, uid: uid, items: Store.for_user(uid))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    Store.delete(String.to_integer(id))
    {:noreply, assign(socket, items: Store.for_user(socket.assigns.uid))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <p :if={message = Phoenix.Flash.get(@flash, :error)} id="flash">{message}</p>
    <ul>
      <li :for={item <- @items} id={"item-#{item.id}"}>
        {item.title} <button phx-click="delete" phx-value-id={item.id}>delete</button>
      </li>
    </ul>
    """
  end
end
