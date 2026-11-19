defmodule Course.Ch04.Producer do
  @moduledoc "Records the events it is sent. `events/0` lists them, oldest first."

  use GenServer

  @spec start_link(term()) :: GenServer.on_start()
  def start_link(_arg), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @spec events() :: [term()]
  def events, do: GenServer.call(__MODULE__, :events)

  @impl true
  def init(events), do: {:ok, events}

  @impl true
  def handle_call({:event, event}, _from, events), do: {:reply, :ok, [event | events]}
  def handle_call(:events, _from, events), do: {:reply, Enum.reverse(events), events}
end

defmodule Course.Ch04.Consumer do
  @moduledoc """
  Forwards each pushed event to `Course.Ch04.Producer` and counts them. It looks the
  producer's pid up once, when it starts, and sends every event to that pid. `push/1` returns
  the producer's reply.
  """

  use GenServer

  alias Course.Ch04.Producer

  @spec start_link(term()) :: GenServer.on_start()
  def start_link(_arg), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @spec push(term()) :: :ok
  def push(event), do: GenServer.call(__MODULE__, {:push, event})

  @impl true
  def init(:ok), do: {:ok, %{producer: Process.whereis(Producer), pushed: 0}}

  @impl true
  def handle_call({:push, event}, _from, state) do
    reply = GenServer.call(state.producer, {:event, event})
    {:reply, reply, %{state | pushed: state.pushed + 1}}
  end
end
