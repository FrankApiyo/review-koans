defmodule Checks.Ch05.RateLimit do
  use Koans.Checks, review: Review.Ch05.RateLimit

  alias Koans.Hidden
  alias Review.Ch05.RateLimit

  @impl true
  def cases do
    [
      {:twin, "a client nobody has counted reads zero",
       fn -> assert {:ok, 0} = Hidden.isolated(&unseen_client/0) end},
      {:exploit, "requests count themselves from their own processes",
       fn -> assert {:ok, {1, 2, 2}} = Hidden.isolated(&requests_count/0) end}
    ]
  end

  defp unseen_client do
    {:ok, limiter} = RateLimit.start_link([])
    RateLimit.count(RateLimit.table(limiter), "10.0.0.1")
  end

  defp requests_count do
    {:ok, limiter} = RateLimit.start_link([])
    table = RateLimit.table(limiter)
    first = RateLimit.hit(table, "10.0.0.1")
    second = Task.await(Task.async(fn -> RateLimit.hit(table, "10.0.0.1") end))
    {first, second, RateLimit.count(table, "10.0.0.1")}
  end
end
