defmodule Checks.HiddenRaised.Cart do
  use Koans.Checks, review: Review.HiddenRaised.Cart

  alias Review.HiddenRaised.Cart

  @impl true
  def cases do
    [
      {:exploit, "a line with no qty counts once",
       fn -> assert 9907 = Cart.total([%{unit_cents: 9907}]) end}
    ]
  end
end
