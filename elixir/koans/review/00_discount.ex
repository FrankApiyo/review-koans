defmodule Review.Ch00.Discount do
  @moduledoc "Prices are in whole cents; a discount is a whole percent from 0 to 100."

  @spec apply(non_neg_integer(), 0..100) :: non_neg_integer()
  def apply(price_cents, percent) do
    price_cents - div(price_cents * percent, 10)
  end
end
