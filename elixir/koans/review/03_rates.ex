defmodule Review.Ch03.Rates do
  @moduledoc """
  Caches exchange rates for the app. `refresh/1` asks `fetch`, a call to a remote API, for
  new rates; `get/1` returns the rates held now.
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
  def handle_cast(:refresh, state), do: {:noreply, %{state | rates: state.fetch.()}}
end
