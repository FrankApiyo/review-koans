defmodule Review.Ch02.WorkerStop do
  @moduledoc """
  A worker is a plain process that answers `{:ping, from}` with `:pong`. `stop/1` stops it
  and returns `:ok`.
  """

  @spec start() :: pid()
  def start, do: spawn(fn -> loop() end)

  @spec stop(pid()) :: :ok
  def stop(pid) do
    # >>> fix
    # also: def stop(pid) do — a reviewer points at the function whose one job is the stop that does nothing
    Process.exit(pid, :normal)
    # === fixed
    Process.exit(pid, :shutdown)
    # === alt: an untrappable kill
    Process.exit(pid, :kill)
    # === wrong: refuses — refuses to stop a worker
    _ = pid
    raise ArgumentError, "workers cannot be stopped"
    # === wrong: partial — GenServer.stop waits for a reply only an OTP process sends
    GenServer.stop(pid)
    # <<<
    :ok
  end

  defp loop do
    receive do
      {:ping, from} ->
        send(from, :pong)
        loop()
    end
  end
end
