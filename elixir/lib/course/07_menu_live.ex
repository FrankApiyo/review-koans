defmodule Course.Ch07.MenuLive do
  @moduledoc """
  A drinks menu: picking a drink shows its name. Each event's params are also sent to the
  session's `"observer"` pid, so a test can read what reached `handle_event/3`.
  """

  use Phoenix.LiveView

  @drinks [%{id: 1, name: "tea"}, %{id: 2, name: "coffee"}]

  @impl true
  def mount(_params, %{"observer" => observer}, socket) do
    {:ok, assign(socket, observer: observer, drinks: @drinks, picked: nil)}
  end

  @impl true
  def handle_event("pick", %{"id" => id} = params, socket) do
    send(socket.assigns.observer, {:params, params})
    {:noreply, assign(socket, picked: Enum.find(socket.assigns.drinks, &(&1.id == id)))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <button :for={drink <- @drinks} phx-click="pick" phx-value-id={drink.id}>{drink.name}</button>
    <p id="picked">{if @picked, do: @picked.name, else: "none"}</p>
    """
  end
end
