defmodule Checks.Ch00.Discount do
  use Koans.Checks, review: Review.Ch00.Discount

  alias Review.Ch00.Discount

  # Twins come first: the buggy module passes them, and a fix that refuses everything fails them.
  @impl true
  def cases do
    [
      {:twin, "a price with no discount", fn -> assert 1000 = Discount.discounted(1000, 0) end},
      {:exploit, "an ordinary discount", fn -> assert 900 = Discount.discounted(1000, 10) end},
      {:exploit, "a discount that does not divide evenly",
       fn -> assert 900 = Discount.discounted(999, 10) end}
    ]
  end
end
