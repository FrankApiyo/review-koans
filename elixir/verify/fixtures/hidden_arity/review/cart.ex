defmodule Review.HiddenArity.Cart do
  def add(items, qty, _opts) when qty > 0, do: {:ok, [qty | items]}
  def add(_items, _qty, _opts), do: {:error, :bad_qty}
end
