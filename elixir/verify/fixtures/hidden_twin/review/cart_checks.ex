defmodule Checks.HiddenTwin.Cart do
  @behaviour Koans.Checks

  import ExUnit.Assertions

  alias Review.HiddenTwin.Cart

  @impl true
  def cases do
    [
      {:exploit, "an empty add", fn -> assert {:error, :bad_qty} = Cart.add([:plum_4417], 0) end},
      {:twin, "a positive add",
       fn -> assert {:ok, [2, :plum_4417]} = Cart.add([:plum_4417], 2) end}
    ]
  end
end
