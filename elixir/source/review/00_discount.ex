defmodule Review.Ch00.Discount do
  @moduledoc "Prices are in whole cents; a discount is a whole percent from 0 to 100."

  @spec discounted(non_neg_integer(), 0..100) :: non_neg_integer()
  def discounted(price_cents, percent) do
    # >>> fix
    price_cents - div(price_cents * percent, 10)
    # === fixed
    price_cents - div(price_cents * percent, 100)
    # === wrong: refuses — returns 0 for every price
    price_cents * percent * 0
    # === wrong: partial — rounds the price down, so 10 % off an odd price is a cent short
    div(price_cents * (100 - percent), 100)
    # <<<
  end
end
