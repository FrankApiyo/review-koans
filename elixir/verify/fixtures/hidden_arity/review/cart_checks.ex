defmodule Checks.HiddenArity.Cart do
  use Koans.Checks, review: Review.HiddenArity.Cart

  alias Review.HiddenArity.Cart

  @impl true
  def cases do
    [
      {:exploit, "an empty add", fn -> assert {:error, :bad_qty} = Cart.add([:fig_3391], 0) end},
      {:twin, "a positive add", fn -> assert {:ok, [2, :fig_3391]} = Cart.add([:fig_3391], 2) end}
    ]
  end
end
