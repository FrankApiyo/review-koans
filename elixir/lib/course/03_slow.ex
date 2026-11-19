defmodule Course.Ch03.Slow do
  @moduledoc "Answers `:slow` only once it receives `:release`, and `:ping` at once."

  use GenServer

  @spec start_link(term()) :: GenServer.on_start()
  def start_link(_arg), do: GenServer.start_link(__MODULE__, :ok)

  @impl true
  def init(:ok), do: {:ok, :idle}

  @impl true
  def handle_call(:slow, _from, state) do
    receive do
      :release -> {:reply, :done, state}
    end
  end

  def handle_call(:ping, _from, state), do: {:reply, :pong, state}
end
