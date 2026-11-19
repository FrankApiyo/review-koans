defmodule Course.Ch01.Invoice do
  @moduledoc "Each invoice line holds a quantity and a unit price in cents."

  @spec total([%{qty: non_neg_integer(), unit: non_neg_integer()}]) :: non_neg_integer()
  def total(lines) do
    Enum.reduce(lines, 0, fn %{qty: qty, unit: unit}, acc -> acc + qty * unit end)
  end
end
