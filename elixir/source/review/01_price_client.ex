defmodule Review.Ch01.PriceClient do
  @moduledoc """
  A price server looks up one SKU per request and replies `{tag, price}` to the `{caller, tag}`
  it was given. `fetch/3` asks it for a price and gives up after `timeout` milliseconds.
  """

  @spec start((String.t() -> non_neg_integer() | nil)) :: pid()
  def start(lookup), do: spawn_link(fn -> serve(lookup) end)

  @spec fetch(pid(), String.t(), timeout()) :: {:ok, non_neg_integer() | nil} | {:error, :timeout}
  def fetch(server, sku, timeout \\ 5000) do
    # >>> fix
    send(server, {:price, sku, {self(), :price}})

    receive do
      {:price, price} -> {:ok, price}
    after
      timeout -> {:error, :timeout}
    # === fixed
    ref = make_ref()
    send(server, {:price, sku, {self(), ref}})

    receive do
      {^ref, price} -> {:ok, price}
    after
      timeout -> {:error, :timeout}
    # === alt: a monitor on the server as the request's tag, removed on every path
    ref = Process.monitor(server)
    send(server, {:price, sku, {self(), ref}})

    receive do
      {^ref, price} ->
        Process.demonitor(ref, [:flush])
        {:ok, price}
    after
      timeout ->
        Process.demonitor(ref, [:flush])
        {:error, :timeout}
    # === wrong: partial — tags the request with a monitor on the server but keeps it after a timeout
    ref = Process.monitor(server)
    send(server, {:price, sku, {self(), ref}})

    receive do
      {^ref, price} ->
        Process.demonitor(ref, [:flush])
        {:ok, price}
    after
      timeout -> {:error, :timeout}
    # === wrong: refuses — takes the reply but reports every request as timed out
    send(server, {:price, sku, {self(), make_ref()}})

    receive do
      {_tag, _price} -> {:error, :timeout}
    after
      timeout -> {:error, :timeout}
    # === wrong: partial — tags the request with a ref but leaves it unpinned in the receive
    ref = make_ref()
    send(server, {:price, sku, {self(), ref}})

    receive do
      {_ref, price} -> {:ok, price}
    after
      timeout -> {:error, :timeout}
    # === wrong: partial — drops every waiting message before asking, other callers' included
    {:messages, waiting} = Process.info(self(), :messages)
    Enum.each(waiting, fn message -> receive(do: (^message -> :ok)) end)
    send(server, {:price, sku, {self(), :price}})

    receive do
      {:price, price} -> {:ok, price}
    after
      timeout -> {:error, :timeout}
    # === wrong: partial — drops only stale replies before asking, so one still on its way gets through
    drop_stale = fn drop_stale ->
      receive do
        {:price, _price} -> drop_stale.(drop_stale)
      after
        0 -> :ok
      end
    end

    drop_stale.(drop_stale)
    send(server, {:price, sku, {self(), :price}})

    receive do
      {:price, price} -> {:ok, price}
    after
      timeout -> {:error, :timeout}
    # <<<
    end
  end

  defp serve(lookup) do
    receive do
      {:price, sku, {caller, tag}} ->
        send(caller, {tag, lookup.(sku)})
        serve(lookup)
    end
  end
end
