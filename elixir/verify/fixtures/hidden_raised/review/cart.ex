defmodule Review.HiddenRaised.Cart do
  def total(lines), do: Enum.reduce(lines, 0, &(Map.fetch!(&1, :qty) * &1.unit_cents + &2))
end
