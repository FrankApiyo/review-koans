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
    # >>> fix
    spawn(fn -> send(parent, {:done, Thumb.resize!(image)}) end)

    receive do
      {:done, thumb} -> {:ok, thumb}
    # === fixed
    {pid, ref} = spawn_monitor(fn -> send(parent, {:done, self(), Thumb.resize!(image)}) end)

    receive do
      {:done, ^pid, thumb} ->
        Process.demonitor(ref, [:flush])
        {:ok, thumb}

      {:DOWN, ^ref, :process, ^pid, reason} ->
        {:error, reason}
    # === alt: the worker exits with its result, and the :DOWN reason carries it
    {pid, ref} = spawn_monitor(fn -> exit({:done, Thumb.resize!(image)}) end)

    receive do
      {:DOWN, ^ref, :process, ^pid, {:done, thumb}} -> {:ok, thumb}
      {:DOWN, ^ref, :process, ^pid, reason} -> {:error, reason}
    # === wrong: refuses — starts the worker but never waits for it
    spawn(fn -> send(parent, {:done, Thumb.resize!(image)}) end)

    receive do
      {:done, _thumb} -> {:error, :busy}
    # === wrong: partial — gives up after a timeout, so the crash reason is lost
    spawn(fn -> send(parent, {:done, Thumb.resize!(image)}) end)

    receive do
      {:done, thumb} -> {:ok, thumb}
    after
      500 -> {:error, :timeout}
    # === wrong: partial — links the worker, so its crash takes the caller down with it
    spawn_link(fn -> send(parent, {:done, Thumb.resize!(image)}) end)

    receive do
      {:done, thumb} -> {:ok, thumb}
    # === wrong: partial — monitors the worker but never demonitors after a result
    {pid, ref} = spawn_monitor(fn -> send(parent, {:done, self(), Thumb.resize!(image)}) end)

    receive do
      {:done, ^pid, thumb} ->
        {:ok, thumb}

      {:DOWN, ^ref, :process, ^pid, reason} ->
        {:error, reason}
    # <<<
    end
  end
end
