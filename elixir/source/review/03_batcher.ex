defmodule Review.Ch03.Batcher do
  @moduledoc """
  Groups items into batches of `size`. `add/2` returns `:ok` once the batch holding its item
  is full and flushed, so each caller waits for its own batch. `flushed/1` returns the
  batches flushed so far, newest first, and `pending/1` how many callers are still waiting.
  """

  use GenServer

  @spec start_link(pos_integer()) :: GenServer.on_start()
  def start_link(size), do: GenServer.start_link(__MODULE__, size)

  @spec add(GenServer.server(), term()) :: :ok
  def add(batcher, item), do: GenServer.call(batcher, {:add, item}, :infinity)

  @spec flushed(GenServer.server()) :: [[term()]]
  def flushed(batcher), do: GenServer.call(batcher, :flushed)

  @spec pending(GenServer.server()) :: non_neg_integer()
  def pending(batcher), do: GenServer.call(batcher, :pending)

  @impl true
  def init(size), do: {:ok, %{size: size, items: [], waiting: [], flushed: []}}

  @impl true
  def handle_call(:flushed, _from, state), do: {:reply, state.flushed, state}
  def handle_call(:pending, _from, state), do: {:reply, length(state.waiting), state}

  # >>> fix
  def handle_call({:add, item}, from, state) do
    state = %{state | items: [item | state.items], waiting: [from | state.waiting]}

    if length(state.items) == state.size do
      GenServer.reply(from, :ok)
      batch = Enum.reverse(state.items)
      {:noreply, %{state | items: [], waiting: [], flushed: [batch | state.flushed]}}
    else
      {:noreply, state}
    end
  end
  # === fixed
  def handle_call({:add, item}, from, state) do
    state = %{state | items: [item | state.items], waiting: [from | state.waiting]}

    if length(state.items) == state.size do
      Enum.each(state.waiting, &GenServer.reply(&1, :ok))
      batch = Enum.reverse(state.items)
      {:noreply, %{state | items: [], waiting: [], flushed: [batch | state.flushed]}}
    else
      {:noreply, state}
    end
  end
  # === alt: answer the earlier callers with GenServer.reply and the last one with :reply
  def handle_call({:add, item}, from, state) do
    items = [item | state.items]

    if length(items) == state.size do
      Enum.each(state.waiting, &GenServer.reply(&1, :ok))
      batch = Enum.reverse(items)
      {:reply, :ok, %{state | items: [], waiting: [], flushed: [batch | state.flushed]}}
    else
      {:noreply, %{state | items: items, waiting: [from | state.waiting]}}
    end
  end
  # === wrong: refuses — turns every item away
  def handle_call({:add, _item}, _from, state), do: {:reply, {:error, :closed}, state}
  # === wrong: partial — answers every caller but keeps them in waiting
  def handle_call({:add, item}, from, state) do
    state = %{state | items: [item | state.items], waiting: [from | state.waiting]}

    if length(state.items) == state.size do
      Enum.each(state.waiting, &GenServer.reply(&1, :ok))
      batch = Enum.reverse(state.items)
      {:noreply, %{state | items: [], flushed: [batch | state.flushed]}}
    else
      {:noreply, state}
    end
  end
  # === wrong: partial — answers the callers stored earlier but not the one that fills the batch
  def handle_call({:add, item}, from, state) do
    if length(state.items) + 1 == state.size do
      Enum.each(state.waiting, &GenServer.reply(&1, :ok))
      batch = Enum.reverse([item | state.items])
      {:noreply, %{state | items: [], waiting: [], flushed: [batch | state.flushed]}}
    else
      {:noreply, %{state | items: [item | state.items], waiting: [from | state.waiting]}}
    end
  end
  # <<<
end
