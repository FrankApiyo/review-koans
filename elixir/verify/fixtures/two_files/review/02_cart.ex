defmodule Review.TwoFiles.Cart do
  def add(items, qty) when qty >= 0, do: {:ok, [qty | items]}
  def add(_items, _qty), do: {:error, :bad_qty}
end
