defmodule Review.Ch01.Thumbnails do
  @moduledoc """
  `render/1` resizes an image in a worker process with `Course.Ch01.Thumb.resize!/1`. It
  returns `{:ok, thumbnail}`, or `{:error, reason}` with the worker's exit reason when the
  worker crashes.
  """

  alias Course.Ch01.Thumb

  @spec render(map()) :: {:ok, map()} | {:error, term()}
  def render(image) do
    parent = self()
    spawn(fn -> send(parent, {:done, Thumb.resize!(image)}) end)

    receive do
      {:done, thumb} -> {:ok, thumb}
    end
  end
end
