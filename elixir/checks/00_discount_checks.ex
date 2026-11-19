defmodule Checks.Ch00.Discount do
  use Koans.Checks, review: Review.Ch00.Discount

  alias Review.Ch00.Discount

  # Twins come first: the buggy module passes them, and a fix that refuses everything fails them.
  @impl true
  def cases do
    [
      {:twin, "a price with no discount", fn -> assert 1000 = Discount.apply(1000, 0) end},
      {:exploit, "a ten percent discount", fn -> assert 900 = Discount.apply(1000, 10) end},
      {:exploit, "a discount on an odd price", fn -> assert 900 = Discount.apply(999, 10) end}
    ]
  end
end
