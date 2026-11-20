defmodule Checks.Ch05.RateLimit do
  use Koans.Checks, review: Review.Ch05.RateLimit

  alias Koans.Hidden
  alias Review.Ch05.RateLimit

  @impl true
  def cases do
    [
      {:twin, "a client nobody has counted reads zero",
       fn -> assert {:ok, 0} = Hidden.isolated(fn -> with_limiter(&unseen_client/1) end) end},
      {:exploit, "requests count themselves from their own processes",
       fn ->
         assert {:ok, {1, 2, 2}} = Hidden.isolated(fn -> with_limiter(&requests_count/1) end)
       end}
    ]
  end

  defp unseen_client(limiter), do: RateLimit.count(RateLimit.table(limiter), "10.0.0.1")

  defp requests_count(limiter) do
    table = RateLimit.table(limiter)
    first = RateLimit.hit(table, "10.0.0.1")
    second = Task.await(Task.async(fn -> RateLimit.hit(table, "10.0.0.1") end))
    {first, second, RateLimit.count(table, "10.0.0.1")}
  end

  # The limiter is registered, so each case starts once no earlier limiter is left, and stops
  # its own before it returns.
  defp with_limiter(fun) do
    true = Hidden.wait_until(fn -> is_nil(Process.whereis(RateLimit)) end)
    {:ok, limiter} = RateLimit.start_link([])
    result = fun.(limiter)
    :ok = GenServer.stop(limiter)
    result
  end
end
