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
    {pid, ref} = spawn_monitor(fn -> send(parent, {:done, self(), Thumb.resize!(image)}) end)

    receive do
      {:done, ^pid, thumb} ->
        Process.demonitor(ref, [:flush])
        {:ok, thumb}

      {:DOWN, ^ref, :process, ^pid, reason} ->
        {:error, reason}
    end
  end
end
