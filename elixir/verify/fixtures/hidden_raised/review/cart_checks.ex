defmodule Checks.HiddenRaised.Cart do
  @behaviour Koans.Checks

  import ExUnit.Assertions

  alias Review.HiddenRaised.Cart

  @impl true
  def cases do
    [
      {:exploit, "a line with no qty counts once",
       fn -> assert Cart.total([%{unit_cents: 9907}]) == 9907 end}
    ]
  end
end
