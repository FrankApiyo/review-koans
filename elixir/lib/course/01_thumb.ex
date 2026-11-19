defmodule Course.Ch01.Thumb do
  @moduledoc "Halves an image's width and height. An image with no area has no clause."

  @spec resize!(%{w: pos_integer(), h: pos_integer()}) :: %{
          w: non_neg_integer(),
          h: non_neg_integer()
        }
  def resize!(%{w: w, h: h}) when w > 0 and h > 0, do: %{w: div(w, 2), h: div(h, 2)}
end
