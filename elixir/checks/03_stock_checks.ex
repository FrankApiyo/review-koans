defmodule Checks.Ch03.Stock do
  use Koans.Checks, review: Review.Ch03.Stock

  alias Koans.Hidden
  alias Review.Ch03.Stock

  @impl true
  def cases do
    [
      {:twin, "one customer after another takes the last unit, then finds it gone",
       fn ->
         assert {:ok, {:ok, {:error, :out_of_stock}, 0}} = Hidden.isolated(&one_after_another/0)
       end},
      {:twin, "a reservation takes several units",
       fn -> assert {:ok, {:ok, 3}} = Hidden.isolated(&several_units/0) end},
      {:exploit, "two customers reserve the last unit at once",
       fn ->
         assert {:ok, {[:ok, {:error, :out_of_stock}], 0}} = Hidden.isolated(&two_at_once/0)
       end}
    ]
  end

  defp one_after_another do
    {:ok, stock} = Stock.start_link(1)
    first = Stock.reserve(stock, 1)
    second = Stock.reserve(stock, 1)
    {first, second, Stock.available(stock)}
  end

  defp several_units do
    {:ok, stock} = Stock.start_link(5)
    {Stock.reserve(stock, 2), Stock.available(stock)}
  end

  # The server is suspended until both customers' first requests wait in its mailbox, so it
  # serves them back to back.
  defp two_at_once do
    test = self()
    {:ok, stock} = Stock.start_link(1)
    :ok = :sys.suspend(stock)
    first = spawn_link(fn -> send(test, {:reserved, self(), Stock.reserve(stock, 1)}) end)
    true = Hidden.wait_until(fn -> queued(stock) > 0 end)
    second = spawn_link(fn -> send(test, {:reserved, self(), Stock.reserve(stock, 1)}) end)
    true = Hidden.wait_until(fn -> queued(stock) > 1 end)
    :ok = :sys.resume(stock)
    results = Enum.map([first, second], &reserved/1)
    {Enum.sort(results), Stock.available(stock)}
  end

  defp reserved(customer) do
    receive do
      {:reserved, ^customer, result} -> result
    end
  end

  defp queued(pid) do
    {:message_queue_len, length} = Process.info(pid, :message_queue_len)
    length
  end
end
