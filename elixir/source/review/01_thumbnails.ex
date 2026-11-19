defmodule Review.Ch01.Thumbnails do
  @moduledoc """
  `render/2` resizes an image in a worker process with `resize`, by default
  `Course.Ch01.Thumb.resize!/1`. It returns `{:ok, thumbnail}`, or `{:error, reason}` with the
  worker's exit reason when the worker crashes.
  """

  alias Course.Ch01.Thumb

  @spec render(map(), (map() -> map())) :: {:ok, map()} | {:error, term()}
  def render(image, resize \\ &Thumb.resize!/1) do
    parent = self()
    # >>> fix
    spawn(fn -> send(parent, {:done, resize.(image)}) end)

    receive do
      {:done, thumb} -> {:ok, thumb}
    # === fixed
    {pid, ref} = spawn_monitor(fn -> send(parent, {:done, self(), resize.(image)}) end)

    receive do
      {:done, ^pid, thumb} ->
        Process.demonitor(ref, [:flush])
        {:ok, thumb}

      {:DOWN, ^ref, :process, ^pid, reason} ->
        {:error, reason}
    # === alt: the worker exits with its result, and the :DOWN reason carries it
    {pid, ref} = spawn_monitor(fn -> exit({:done, resize.(image)}) end)

    receive do
      {:DOWN, ^ref, :process, ^pid, {:done, thumb}} -> {:ok, thumb}
      {:DOWN, ^ref, :process, ^pid, reason} -> {:error, reason}
    # === alt: Process.spawn with :monitor, and the result tagged with a fresh ref
    tag = make_ref()
    {pid, ref} = Process.spawn(fn -> send(parent, {tag, resize.(image)}) end, [:monitor])

    receive do
      {^tag, thumb} ->
        Process.demonitor(ref, [:flush])
        {:ok, thumb}

      {:DOWN, ^ref, :process, ^pid, reason} ->
        {:error, reason}
    # === wrong: refuses — waits for the worker, then reports it busy
    spawn(fn -> send(parent, {:done, resize.(image)}) end)

    receive do
      {:done, _thumb} -> {:error, :busy}
    # === wrong: partial — gives up after a timeout, so the crash reason is lost
    spawn(fn -> send(parent, {:done, resize.(image)}) end)

    receive do
      {:done, thumb} -> {:ok, thumb}
    after
      500 -> {:error, :timeout}
    # === wrong: partial — links the worker, so its crash takes the caller down with it
    spawn_link(fn -> send(parent, {:done, resize.(image)}) end)

    receive do
      {:done, thumb} -> {:ok, thumb}
    # === wrong: partial — monitors the worker but never demonitors after a result
    {pid, ref} = spawn_monitor(fn -> send(parent, {:done, self(), resize.(image)}) end)

    receive do
      {:done, ^pid, thumb} ->
        {:ok, thumb}

      {:DOWN, ^ref, :process, ^pid, reason} ->
        {:error, reason}
    # <<<
    end
  end
end
