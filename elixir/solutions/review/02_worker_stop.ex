defmodule Review.Ch02.WorkerStop do
  @moduledoc """
  A worker is a plain process that answers `{:ping, from}` with `:pong`. `stop/1` stops it
  and returns `:ok`.
  """

  @spec start() :: pid()
  def start, do: spawn(fn -> loop() end)

  @spec stop(pid()) :: :ok
  def stop(pid) do
    Process.exit(pid, :shutdown)
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
