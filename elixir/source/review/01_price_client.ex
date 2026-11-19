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
    # === fixed
    ref = make_ref()
    send(server, {:price, sku, {self(), ref}})

    receive do
      {^ref, price} -> {:ok, price}
    # === wrong: refuses — takes the reply but reports every request as timed out
    send(server, {:price, sku, {self(), make_ref()}})

    receive do
      {_tag, _price} -> {:error, :timeout}
    # === wrong: partial — tags the request with a ref but leaves it unpinned in the receive
    ref = make_ref()
    send(server, {:price, sku, {self(), ref}})

    receive do
      {_ref, price} -> {:ok, price}
    # === wrong: partial — drops every waiting message before asking, other callers' included
    {:messages, waiting} = Process.info(self(), :messages)
    Enum.each(waiting, fn message -> receive(do: (^message -> :ok)) end)
    send(server, {:price, sku, {self(), :price}})

    receive do
      {:price, price} -> {:ok, price}
    # <<<
    after
      timeout -> {:error, :timeout}
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
