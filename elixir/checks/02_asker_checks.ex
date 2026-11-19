defmodule Checks.Ch02.Asker do
  use Koans.Checks, review: Review.Ch02.Asker

  alias Koans.Hidden
  alias Review.Ch02.Asker

  @impl true
  def cases do
    [
      {:twin, "answers from a live server",
       fn ->
         assert {:ok, [ok: 1, ok: 4, ok: 9]} =
                  Hidden.isolated(fn -> Enum.map(1..3, &Asker.ask(squarer(), &1)) end)
       end},
      {:twin, "messages meant for someone else stay in the mailbox",
       fn ->
         assert {:ok, {{:ok, 4}, [{:keep, 1}, {:DOWN, _, :process, _, :normal}]}} =
                  Hidden.isolated(&ask_beside_unrelated/0)
       end},
      {:exploit, "asking many times leaves no monitor behind",
       fn ->
         assert {:ok, []} = Hidden.isolated(&monitors_after_asks/0)
       end},
      {:exploit, "an answer from a server that then dies leaves no :DOWN behind",
       fn -> assert {:ok, {{:ok, 9}, [{:keep, 1}]}} = Hidden.isolated(&ask_dying_server/0) end}
    ]
  end

  defp ask_beside_unrelated do
    send(self(), {:keep, 1})
    send(self(), {:DOWN, make_ref(), :process, self(), :normal})
    answer = Asker.ask(squarer(), 2)
    {:messages, left} = Process.info(self(), :messages)
    {answer, left}
  end

  defp monitors_after_asks do
    server = squarer()
    Enum.each(1..3, &Asker.ask(server, &1))
    {:monitors, monitors} = Process.info(self(), :monitors)
    monitors
  end

  # The caller is suspended until the answer and the server's :DOWN have both reached it,
  # so it reads them together.
  defp ask_dying_server do
    test = self()
    server = spawn_link(fn -> forward_one(test) end)

    caller =
      spawn_link(fn ->
        send(self(), {:keep, 1})
        answer = Asker.ask(server, 3)
        {:messages, left} = Process.info(self(), :messages)
        send(test, {:asked, self(), answer, left})
      end)

    receive do
      {:forwarded, ^caller, ref, question} ->
        :erlang.suspend_process(caller)
        send(caller, {:answer, ref, question * question})
        stop(server)
        true = Hidden.wait_until(fn -> queued(caller) > 2 end)
        :erlang.resume_process(caller)
    end

    receive do
      {:asked, ^caller, answer, left} -> {answer, left}
    end
  end

  defp squarer, do: spawn_link(fn -> square_loop() end)

  defp square_loop do
    receive do
      {:ask, from, ref, question} ->
        send(from, {:answer, ref, question * question})
        square_loop()
    end
  end

  defp forward_one(test) do
    receive do
      {:ask, from, ref, question} -> send(test, {:forwarded, from, ref, question})
    end

    receive do
      :stop -> :ok
    end
  end

  defp stop(server) do
    ref = Process.monitor(server)
    send(server, :stop)

    receive do
      {:DOWN, ^ref, :process, ^server, _reason} -> :ok
    end
  end

  defp queued(pid) do
    {:message_queue_len, length} = Process.info(pid, :message_queue_len)
    length
  end
end
