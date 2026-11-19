defmodule Koans.Ch01.ProcessesAndMailboxesTest do
  @moduledoc ~S"""
  Look for: a `receive` that can take a message meant for another request (no ref, or a ref
  left unpinned); a `receive` with no way out when the other process dies; a loop that leaves
  unknown messages in its mailbox; and `self()` called inside the function a new process runs.

  Why it bites: a late reply answers the next request, so one customer sees another's price.
  A mailbox nothing drains grows until the node runs out of memory. A worker that crashes
  before it replies leaves its caller waiting forever.

  Review habit: Name the other process. For each `send`, say who receives it and what happens
  if that process is dead, slow or never answers. For each `receive`, say who sends what it
  matches, and what else could be in the mailbox when it runs. Messages from one process
  arrive in the order it sent them; that is the only ordering the runtime promises, so a
  result sent just before its sender exits always arrives before the `:DOWN`.

  A common mistake: flushing the mailbox, or adding `after`, instead of tagging the request.
  A flush throws away messages meant for other code; a timeout turns a crash into `:timeout`
  and loses the reason. Put a `make_ref()` in the request and pin it in the `receive`. OTP's
  `GenServer.call` tags its requests for the same reason (chapter 3). The stale reply still
  sits in the mailbox, so a long-lived caller must drop it later or not care.

  Read more: https://hexdocs.pm/elixir/1.19.5/processes.html,
  https://hexdocs.pm/elixir/1.19.5/Process.html,
  https://www.erlang.org/doc/system/ref_man_processes.html
  """
  use Koans

  koan "A process has run and exited. What does send to it return, and is it alive?" do
    pid = spawn(fn -> :ok end)
    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, :process, ^pid, _reason} -> :ok
    end

    assert send(pid, :hello) == :hello
    assert Process.alive?(pid) == false
  end

  koan "receive takes the first message that matches. What is left waiting, and what comes next?" do
    send(self(), :a)
    send(self(), :b)
    send(self(), :c)

    receive do
      :b -> :ok
    end

    {:message_queue_len, waiting} = Process.info(self(), :message_queue_len)

    next =
      receive do
        message -> message
      end

    assert waiting == 2
    assert next == :a
  end

  koan "The caller puts a request id in its process dictionary. What does a Task it starts see?" do
    Process.put(:request_id, "abc")
    task = Task.async(fn -> Process.get(:request_id) end)
    assert Task.await(task) == nil
  end

  koan "Four processes end four ways. Name each :DOWN reason, then how many log an error report: traces/01_invoice.exs runs the same four." do
    lines = [%{qty: 2, unit: 500}, %{qty: "3", unit: 250}]
    {arithmetic, _stack} = exit_reason(fn -> Course.Ch01.Invoice.total(lines) end)
    assert arithmetic == :badarith

    {exception, _stack} = exit_reason(fn -> raise ArgumentError, "qty must be an integer" end)
    assert exception.__struct__ == ArgumentError

    assert exit_reason(fn -> exit(:shutdown) end) == :shutdown

    {thrown, _stack} = exit_reason(fn -> throw(:oops) end)
    assert thrown == {:nocatch, :oops}

    assert Koans.Trace.reports("01_invoice") == 3
  end

  koan "Read traces/01_invoice.exs.trace. Name the exception in the first report, then the file and line it came from." do
    assert Koans.Trace.exception("01_invoice") == "ArithmeticError"
    assert Koans.Trace.first_frame("01_invoice") == {"traces/01_invoice.exs", 3}
  end

  koan "Read koans/review/01_price_client.ex. Write :fine, or the line number of the bug." do
    verdict("01_price_client.ex", 15, "7561b8f9be,9893345e99,cd6ee562cb", "eb2541919c")
  end

  koan "Fix the bug in koans/review/01_price_client.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch01.PriceClient, Review.Ch01.PriceClient)
  end

  koan "Read koans/review/01_tally.ex. Write :fine, or the line number of the bug." do
    verdict("01_tally.ex", 11, "28e5e055e9,77db4cb000,82e4181885,885f470698,ffdc241061", "ee091643b4")
  end

  koan "Fix the bug in koans/review/01_tally.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch01.Tally, Review.Ch01.Tally)
  end

  koan "Read koans/review/01_thumbnails.ex. Write :fine, or the line number of the bug." do
    verdict("01_thumbnails.ex", 13, "4123f0ffdc,57dc1fe89f,eeaa267ed2", "10b8c6052e")
  end

  koan "Fix the bug in koans/review/01_thumbnails.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch01.Thumbnails, Review.Ch01.Thumbnails)
  end

  koan "Read koans/review/01_parallel_map.ex. Write :fine, or the line number of the bug." do
    verdict("01_parallel_map.ex", 8, "0f0f29aaea,724d4f7fbd,c3f74e47ec", "907572b74c")
  end

  koan "Fix the bug in koans/review/01_parallel_map.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch01.ParallelMap, Review.Ch01.ParallelMap)
  end

  koan "Read koans/review/01_ask.ex. Write :fine, or the line number of the bug." do
    verdict("01_ask.ex", :fine, "19085ed757", "c856111231")
    run_checks(Checks.Ch01.Ask, Review.Ch01.Ask)
  end

  defp exit_reason(fun) do
    {pid, ref} = spawn_monitor(fun)

    receive do
      {:DOWN, ^ref, :process, ^pid, reason} -> reason
    end
  end
end
