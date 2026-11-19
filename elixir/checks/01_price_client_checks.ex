defmodule Checks.Ch01.PriceClient do
  use Koans.Checks, review: Review.Ch01.PriceClient

  alias Koans.Hidden
  alias Review.Ch01.PriceClient

  @impl true
  def cases do
    [
      {:twin, "a price for a known SKU",
       fn ->
         assert {:ok, {:ok, 120}} = Hidden.isolated(fn -> fetch_on_quiet_mailbox("apple") end)
       end},
      {:twin, "an SKU the lookup does not know",
       fn ->
         assert {:ok, {:ok, nil}} = Hidden.isolated(fn -> fetch_on_quiet_mailbox("kiwi") end)
       end},
      {:twin, "a message meant for someone else stays in the mailbox",
       fn ->
         assert {:ok, {{:ok, 120}, [{:unrelated, 1}]}} =
                  Hidden.isolated(&fetch_beside_unrelated/0)
       end},
      {:exploit, "a late reply to an abandoned request",
       fn -> assert {:ok, {:ok, 120}} = Hidden.isolated(&fetch_after_late_reply/0) end},
      {:exploit, "a late reply still on its way when the next request is sent",
       fn -> assert {:ok, {:ok, 120}} = Hidden.isolated(&fetch_with_late_reply_in_flight/0) end},
      {:exploit, "a timed-out request leaves no monitor and no :DOWN behind",
       fn -> assert {:ok, {[], []}} = Hidden.isolated(&leftovers_after_timeout/0) end}
    ]
  end

  defp fetch_on_quiet_mailbox(sku) do
    PriceClient.fetch(PriceClient.start(lookup(self())), sku)
  end

  defp fetch_beside_unrelated do
    server = PriceClient.start(lookup(self()))
    send(self(), {:unrelated, 1})
    answer = PriceClient.fetch(server, "apple")
    {:messages, left} = Process.info(self(), :messages)
    {answer, left}
  end

  # The slow lookup holds the server until :release, so a zero timeout cannot see its reply.
  defp fetch_after_late_reply do
    server = PriceClient.start(lookup(self()))
    {:error, :timeout} = PriceClient.fetch(server, "slow", 0)

    receive do
      :slow_started -> send(server, :release)
    end

    true = Hidden.wait_until(fn -> queued(self()) > 0 end)
    PriceClient.fetch(server, "apple")
  end

  # The holder releases the slow lookup only once the next request waits in the server's
  # mailbox, so the late reply is sent after that request and before its answer.
  defp fetch_with_late_reply_in_flight do
    holder = spawn_link(&hold_slow_lookup/0)
    server = PriceClient.start(lookup(holder))
    send(holder, {:server, server})
    {:error, :timeout} = PriceClient.fetch(server, "slow", 0)
    PriceClient.fetch(server, "apple")
  end

  defp hold_slow_lookup do
    receive do
      {:server, server} ->
        receive do
          :slow_started ->
            true = Hidden.wait_until(fn -> queued(server) > 0 end)
            send(server, :release)
        end
    end
  end

  # The server is still blocked in the slow lookup when the monitors are read, then it is
  # killed and its own :DOWN, from the one dying sender, marks that it is gone.
  defp leftovers_after_timeout do
    server = PriceClient.start(lookup(self()))
    {:error, :timeout} = PriceClient.fetch(server, "slow", 0)
    {:monitors, monitors} = Process.info(self(), :monitors)
    Process.unlink(server)
    gone = Process.monitor(server)
    Process.exit(server, :kill)

    receive do
      {:DOWN, ^gone, :process, ^server, :killed} -> :ok
    end

    {:messages, messages} = Process.info(self(), :messages)
    {monitors, for({:DOWN, _, _, _, _} = down <- messages, do: down)}
  end

  defp lookup(caller) do
    fn
      "slow" ->
        send(caller, :slow_started)

        receive do
          :release -> 999
        end

      "apple" ->
        120

      _other ->
        nil
    end
  end

  defp queued(pid) do
    {:message_queue_len, length} = Process.info(pid, :message_queue_len)
    length
  end
end
