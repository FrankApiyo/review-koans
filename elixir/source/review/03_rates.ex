defmodule Review.Ch03.Rates do
  @moduledoc """
  Caches exchange rates for the whole app. `refresh/1` asks `fetch`, a call to a remote API
  that can take seconds, for new rates; `get/1` returns the rates held now, and every request
  that prices something calls it.
  """

  use GenServer

  @spec start_link((-> map())) :: GenServer.on_start()
  def start_link(fetch), do: GenServer.start_link(__MODULE__, fetch)

  @spec refresh(GenServer.server()) :: :ok
  def refresh(rates), do: GenServer.cast(rates, :refresh)

  @spec get(GenServer.server()) :: map()
  def get(rates), do: GenServer.call(rates, :get)

  @impl true
  def init(fetch), do: {:ok, %{fetch: fetch, rates: %{}}}

  @impl true
  def handle_call(:get, _from, state), do: {:reply, state.rates, state}

  @impl true
  # >>> fix
  def handle_cast(:refresh, state), do: {:noreply, %{state | rates: state.fetch.()}}
  # === fixed
  def handle_cast(:refresh, state) do
    server = self()
    Task.start(fn -> send(server, {:rates, state.fetch.()}) end)
    {:noreply, state}
  end

  @impl true
  def handle_info({:rates, rates}, state), do: {:noreply, %{state | rates: rates}}
  # === alt: a plain spawn that sends the rates back
  def handle_cast(:refresh, state) do
    server = self()
    spawn(fn -> send(server, {:rates, state.fetch.()}) end)
    {:noreply, state}
  end

  @impl true
  def handle_info({:rates, rates}, state), do: {:noreply, %{state | rates: rates}}
  # === alt: Task.async, its result taken in handle_info
  def handle_cast(:refresh, state) do
    Task.async(state.fetch)
    {:noreply, state}
  end

  @impl true
  def handle_info({ref, rates}, state) when is_reference(ref) do
    Process.demonitor(ref, [:flush])
    {:noreply, %{state | rates: rates}}
  end
  # === wrong: refuses — never fetches new rates
  def handle_cast(:refresh, state), do: {:noreply, state}
  # === wrong: partial — runs the fetch in a Task but waits for it inside the callback
  def handle_cast(:refresh, state) do
    rates = state.fetch |> Task.async() |> Task.await(:infinity)
    {:noreply, %{state | rates: rates}}
  end
  # === wrong: partial — moves the fetch to handle_continue, which still runs in the server
  def handle_cast(:refresh, state), do: {:noreply, state, {:continue, :fetch}}

  @impl true
  def handle_continue(:fetch, state), do: {:noreply, %{state | rates: state.fetch.()}}
  # <<<
end
