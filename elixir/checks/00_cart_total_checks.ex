defmodule Checks.Ch00.CartTotal do
  use Koans.Checks, review: Review.Ch00.CartTotal

  alias Review.Ch00.CartTotal

  @impl true
  def cases do
    [
      {:twin, "an empty cart", fn -> assert 0 = CartTotal.total([]) end},
      {:twin, "single units",
       fn ->
         assert 450 = CartTotal.total([%{qty: 1, unit_cents: 250}, %{qty: 1, unit_cents: 200}])
       end},
      {:exploit, "a line with several units",
       fn ->
         assert 950 = CartTotal.total([%{qty: 3, unit_cents: 250}, %{qty: 1, unit_cents: 200}])
       end}
    ]
  end
end
