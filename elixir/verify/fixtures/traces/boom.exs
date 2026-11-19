defmodule Boom.Board do
  use GenServer

  @impl true
  def init(cells), do: {:ok, cells}

  @impl true
  def handle_info(%{"event" => "mark", "cell" => cell}, cells) do
    {:noreply, Map.put(cells, cell, Map.fetch!(cells, cell) + 1)}
  end
end

defmodule Boom.Counter do
  use GenServer

  @impl true
  def init(count), do: {:ok, count}

  @impl true
  def handle_call({:bump, by}, _from, count) do
    new = count + by
    {:reply, new, new}
  end
end

Process.flag(:trap_exit, true)
{:ok, board} = GenServer.start_link(Boom.Board, %{"a1" => 0}, name: Boom.Board)
send(board, %{"event" => "mark", "cell" => "b2"})

receive do
  {:EXIT, ^board, _reason} -> :ok
end

{:ok, counter} = GenServer.start_link(Boom.Counter, 0)
GenServer.call(counter, {:bump, "two"})
