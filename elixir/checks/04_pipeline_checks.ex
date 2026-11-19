defmodule Checks.Ch04.Pipeline do
  use Koans.Checks, review: Review.Ch04.Pipeline

  alias Course.Ch04.{Consumer, Producer}
  alias Koans.Hidden
  alias Review.Ch04.Pipeline

  @impl true
  def cases do
    [
      {:twin, "a pushed event reaches the producer",
       fn -> assert {:ok, [1]} = Hidden.isolated(&events_after_push/0) end},
      {:twin, "a consumer crash leaves the producer's events in place",
       fn -> assert {:ok, [1]} = Hidden.isolated(&events_after_consumer_crash/0) end},
      {:exploit, "after the producer restarts, a push reaches the new producer",
       fn -> assert {:ok, {:ok, [2]}} = Hidden.isolated(&push_after_producer_crash/0) end}
    ]
  end

  defp events_after_push do
    in_pipeline(fn ->
      :ok = Consumer.push(1)
      Producer.events()
    end)
  end

  defp events_after_consumer_crash do
    in_pipeline(fn ->
      :ok = Consumer.push(1)
      consumer = Process.whereis(Consumer)
      Process.exit(consumer, :kill)
      true = Hidden.wait_until(fn -> restarted?(Consumer, consumer) end)
      Producer.events()
    end)
  end

  # A supervisor stops the children it restarts before it starts any of them again, so once
  # the producer is new, a live consumer is either untouched or already restarted.
  defp push_after_producer_crash do
    in_pipeline(fn ->
      producer = Process.whereis(Producer)
      Process.exit(producer, :kill)

      true =
        Hidden.wait_until(fn ->
          restarted?(Producer, producer) and is_pid(Process.whereis(Consumer))
        end)

      {Consumer.push(2), Producer.events()}
    end)
  end

  defp in_pipeline(run) do
    {:ok, pipeline} = Pipeline.start_link(:ok)
    result = run.()
    :ok = Supervisor.stop(pipeline)
    result
  end

  defp restarted?(name, old) do
    Process.whereis(name) not in [nil, old]
  end
end
