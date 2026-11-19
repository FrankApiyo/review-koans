defmodule Review.HiddenTwin.Cart do
  def add(_items, _qty), do: {:error, :bad_qty}
end
