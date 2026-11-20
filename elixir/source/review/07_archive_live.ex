defmodule Review.Ch07.ArchiveLive do
  @moduledoc """
  The signed-in user's active items, each with an archive button. An archived item leaves the
  list. The session holds the user's id as `"uid"`.
  """

  use Phoenix.LiveView

  alias Course.Ch07.Store

  @impl true
  def mount(_params, %{"uid" => uid}, socket) do
    {:ok, assign(socket, uid: uid, items: Store.for_user(uid))}
  end

  @impl true
  def handle_event("archive", %{"id" => id}, socket) do
    uid = socket.assigns.uid

    # >>> guard
    with {id, ""} <- Integer.parse(id),
         %{user_id: ^uid} <- Store.get(id) do
    # === wrong: partial — matches any item, so a forged event archives another user's
    with {id, ""} <- Integer.parse(id),
         %{} <- Store.get(id) do
    # <<<
      :ok = Store.archive(id)
      {:noreply, assign(socket, items: Store.for_user(uid))}
    else
      _not_found -> {:noreply, put_flash(socket, :error, "Not found")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <p :if={message = Phoenix.Flash.get(@flash, :error)} id="flash">{message}</p>
    <ul>
      <li :for={item <- @items} id={"item-#{item.id}"}>
        {item.title} <button phx-click="archive" phx-value-id={item.id}>archive</button>
      </li>
    </ul>
    """
  end
end
