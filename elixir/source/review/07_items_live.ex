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
    # >>> fix
    # also: def handle_event("delete", %{"id" => id}, socket) do — a reviewer points at the handler that takes any id the client sends
    Store.delete(String.to_integer(id))
    {:noreply, assign(socket, items: Store.for_user(socket.assigns.uid))}
    # === fixed
    uid = socket.assigns.uid

    with {id, ""} <- Integer.parse(id),
         %{user_id: ^uid} <- Store.get(id) do
      :ok = Store.delete(id)
      {:noreply, assign(socket, items: Store.for_user(uid))}
    else
      _not_found -> {:noreply, put_flash(socket, :error, "Not found")}
    end
    # === alt: deletes only an item the view listed for the signed-in user
    case Enum.find(socket.assigns.items, &(Integer.to_string(&1.id) == id)) do
      nil ->
        {:noreply, put_flash(socket, :error, "Not found")}

      item ->
        :ok = Store.delete(item.id)
        {:noreply, assign(socket, items: Store.for_user(socket.assigns.uid))}
    end
    # === alt: authorises in the handler, comparing the owner with the session's user
    with {id, ""} <- Integer.parse(id),
         item when item != nil <- Store.get(id),
         true <- item.user_id == socket.assigns.uid do
      :ok = Store.delete(id)
      {:noreply, assign(socket, items: Store.for_user(socket.assigns.uid))}
    else
      _not_found -> {:noreply, put_flash(socket, :error, "Not found")}
    end
    # === wrong: refuses — deletes nothing
    _ = id
    {:noreply, put_flash(socket, :error, "Not found")}
    # === wrong: partial — parses the id safely, but deletes whoever's item it names
    case Integer.parse(id) do
      {id, ""} -> :ok = Store.delete(id)
      _not_a_number -> :ok
    end

    {:noreply, assign(socket, items: Store.for_user(socket.assigns.uid))}
    # === wrong: partial — checks that the item exists, not whose it is
    with {id, ""} <- Integer.parse(id),
         %{} <- Store.get(id) do
      :ok = Store.delete(id)
      {:noreply, assign(socket, items: Store.for_user(socket.assigns.uid))}
    else
      _not_found -> {:noreply, put_flash(socket, :error, "Not found")}
    end
    # === wrong: partial — scopes the delete, but tells another user's item apart from a missing one
    uid = socket.assigns.uid

    case Integer.parse(id) do
      {id, ""} ->
        case Store.get(id) do
          %{user_id: ^uid} ->
            :ok = Store.delete(id)
            {:noreply, assign(socket, items: Store.for_user(uid))}

          nil ->
            {:noreply, put_flash(socket, :error, "Not found")}

          _not_yours ->
            {:noreply, put_flash(socket, :error, "Not allowed")}
        end

      :error ->
        {:noreply, put_flash(socket, :error, "Not found")}
    end
    # <<<
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
