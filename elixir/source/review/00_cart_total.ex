defmodule Review.Ch00.CartTotal do
  @moduledoc "Each line of a cart holds a quantity and a unit price in cents."

  @spec total([%{qty: pos_integer(), unit_cents: non_neg_integer()}]) :: non_neg_integer()
  def total(lines) do
    Enum.sum_by(lines, fn line ->
      # >>> guard
      line.qty * line.unit_cents
      # === wrong: partial — drops the qty factor
      line.unit_cents
      # <<<
    end)
  end
end
