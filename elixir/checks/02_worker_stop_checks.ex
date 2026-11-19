defmodule Checks.Ch02.WorkerStop do
  use Koans.Checks, review: Review.Ch02.WorkerStop

  alias Koans.Hidden
  alias Review.Ch02.WorkerStop

  @impl true
  def cases do
    [
      {:twin, "a running worker answers a ping",
       fn -> assert {:ok, :pong} = Hidden.isolated(&ping_running/0) end},
      {:twin, "stopping a worker returns :ok",
       fn -> assert {:ok, {:ok, _}} = Hidden.isolated(&stop_and_look/0) end},
      {:exploit, "a stopped worker is no longer alive",
       fn -> assert {:ok, {_, false}} = Hidden.isolated(&stop_and_look/0) end}
    ]
  end

  defp ping_running do
    worker = WorkerStop.start()
    send(worker, {:ping, self()})

    receive do
      :pong ->
        Process.exit(worker, :kill)
        :pong
    end
  end

  # Process.alive?/1 sees every signal this process sent before it, the stop's included.
  defp stop_and_look do
    worker = WorkerStop.start()
    stopped = WorkerStop.stop(worker)
    alive = Process.alive?(worker)
    Process.exit(worker, :kill)
    {stopped, alive}
  end
end
