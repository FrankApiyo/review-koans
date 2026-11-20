defmodule Review.Ch07.NotesLive do
  @moduledoc """
  The signed-in user's notes at `/ch07/notes`, filtered by the tag in the URL, as in
  `/ch07/notes?tag=food`, so a filtered list can be bookmarked. Choosing a tag patches the
  URL: the same LiveView stays, and the browser's back button returns to the previous tag.
  """

  use Phoenix.LiveView

  alias Course.Ch07.Store

  def mount(_params, %{"uid" => uid}, socket), do: {:ok, assign(socket, uid: uid)}

  def handle_params(params, _uri, socket) do
    {:noreply, assign(socket, items: tagged(socket.assigns.uid, params["tag"]))}
  end

  def handle_event("tag", %{"tag" => tag}, socket) do
    {:noreply, push_patch(socket, to: "/ch07/notes?" <> URI.encode_query(tag: tag))}
  end

  defp tag_choice(assigns), do: ~H|<button phx-click="tag" phx-value-tag={@tag}>{@tag}</button>|

  defp tagged(uid, nil), do: Store.for_user(uid)
  defp tagged(uid, tag), do: Enum.filter(Store.for_user(uid), &(&1.tag == tag))

  def render(assigns) do
    ~H"""
    <.tag_choice :for={tag <- ["food", "drink"]} tag={tag} />
    <ul>
      <li :for={item <- @items} id={"item-#{item.id}"}>{item.title}</li>
    </ul>
    """
  end
end
