defmodule Course.Ch07.Store do
  @moduledoc """
  The chapter's items, kept in memory by id. Each item is a map with `:id`, `:title`,
  `:user_id` and `:tag`; an archived item also has `archived: true`.
  """

  use Agent

  @spec start_link([map()]) :: Agent.on_start()
  def start_link(items) do
    Agent.start_link(fn -> Map.new(items, &{&1.id, &1}) end, name: __MODULE__)
  end

  @spec all() :: [map()]
  def all do
    Agent.get(__MODULE__, &(&1 |> Map.values() |> Enum.sort_by(fn item -> item.id end)))
  end

  @spec get(integer()) :: map() | nil
  def get(id), do: Agent.get(__MODULE__, &Map.get(&1, id))

  @doc "The user's items that are not archived, in id order."
  @spec for_user(pos_integer()) :: [map()]
  def for_user(uid) do
    Enum.filter(all(), &(&1.user_id == uid and not Map.get(&1, :archived, false)))
  end

  @spec delete(integer()) :: :ok
  def delete(id), do: Agent.update(__MODULE__, &Map.delete(&1, id))

  @spec archive(integer()) :: :ok
  def archive(id) do
    Agent.update(__MODULE__, fn items ->
      Map.update!(items, id, &Map.put(&1, :archived, true))
    end)
  end
end
