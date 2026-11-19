defmodule Koans.Ch02.LinksMonitorsAndExitsTest do
  @moduledoc ~S"""
  Look for: `spawn_link` or `Task.async` where the caller must outlive the work; a process
  that traps exits but has no clause for `{:EXIT, pid, :normal}`; a monitor still held once
  the answer came; and `Process.exit(pid, :normal)` used to stop a process.

  Why it bites: one bad email address takes the notifier down, and every in-flight
  notification goes with it. A long-lived client that never removes its monitors holds one
  more for every request, and each server that dies leaves a `:DOWN` that nothing reads.

  Review habit: Ask what happens on crash. For each process a line starts or watches, say
  what reaches the other side when it ends, normally or not. The runtime's rules: a link
  carries an exit signal both ways, and a process that does not trap exits dies of any
  reason except `:normal`. Trapping turns the signal into an `{:EXIT, pid, reason}` message,
  `:normal` included. `Process.exit(pid, :kill)` cannot be trapped, and links and monitors
  see the reason `:killed`. A monitor is one-way and delivers one `:DOWN` message. Linking a
  `Task.async` to its caller is Elixir's choice; `Task.Supervisor.async_nolink` monitors
  the task without the link.

  A common mistake: wrapping `spawn_link` in `try/rescue`. The crash happens in the other
  process and arrives as a signal, so no `rescue` in the caller sees it, and trapping exits
  in the caller only turns it into mail the caller must read. Start the process unlinked,
  or monitor it and read the `:DOWN`. Unlinking after the start (`spawn_link` then
  `Process.unlink`, or `Task.async` then `Task.ignore`) leaves a window in which a fast
  crash still takes the caller. Once the answer is in, `Process.demonitor(ref, [:flush])`
  removes the monitor and any `:DOWN` already waiting.

  Read more: https://hexdocs.pm/elixir/1.19.5/Process.html,
  https://hexdocs.pm/elixir/1.19.5/Task.html,
  https://www.erlang.org/doc/apps/erts/erlang.html,
  https://www.erlang.org/doc/system/ref_man_processes.html
  """
  use Koans

  koan "Process.exit(pid, :normal) goes to a process that does not trap exits, then to one that does. Is the first alive, and what does the second receive?" do
    worker = spawn(fn -> answer_pings() end)
    Process.exit(worker, :normal)
    send(worker, {:ping, self()})

    receive do
      :pong -> :ok
    end

    assert Process.alive?(worker) == __
    Process.exit(worker, :kill)

    test = self()

    trapper =
      spawn(fn ->
        Process.flag(:trap_exit, true)
        send(test, :trapping)

        receive do
          message -> send(test, {:got, message})
        end
      end)

    receive do
      :trapping -> Process.exit(trapper, :normal)
    end

    {tag, ^test, reason} =
      receive do
        {:got, message} -> message
      end

    assert {tag, reason} == __
  end

  koan "Process.exit(pid, :kill) goes to a process that traps exits. What :DOWN reason does a monitor see, and what :EXIT reason does a linked, trapping process see?" do
    test = self()
    trapper = spawn(fn -> trap_and_wait(test) end)

    receive do
      :trapping -> :ok
    end

    ref = Process.monitor(trapper)
    Process.exit(trapper, :kill)

    down_reason =
      receive do
        {:DOWN, ^ref, :process, ^trapper, reason} -> reason
      end

    assert down_reason == __

    observer =
      spawn(fn ->
        Process.flag(:trap_exit, true)
        child = spawn_link(fn -> trap_and_wait(test) end)

        receive do
          {:EXIT, ^child, reason} -> send(test, {:observed, reason})
        end
      end)

    child =
      receive do
        :trapping ->
          {:links, [child]} = Process.info(observer, :links)
          child
      end

    Process.exit(child, :kill)

    exit_reason =
      receive do
        {:observed, reason} -> reason
      end

    assert exit_reason == __
  end

  koan "A process has already exited when monitor is called. Does monitor return a reference, and what :DOWN reason arrives?" do
    pid = spawn(fn -> :ok end)
    first = Process.monitor(pid)

    receive do
      {:DOWN, ^first, :process, ^pid, _reason} -> :ok
    end

    ref = Process.monitor(pid)
    assert is_reference(ref) == __

    reason =
      receive do
        {:DOWN, ^ref, :process, ^pid, reason} -> reason
      end

    assert reason == __
  end

  koan "Report.build/1 awaits a Task.async that crashes on a row that is not a string. Name the caller's :DOWN reason, then the module of the top stack frame." do
    {caller, ref} = spawn_monitor(Course.Ch02.Report, :build, [["a", :b]])

    {reason, [{module, _function, _args, _location} | _]} =
      receive do
        {:DOWN, ^ref, :process, ^caller, reason} -> reason
      end

    assert reason == __
    assert module == __
  end

  koan "Read traces/02_report.exs.trace. Which kind of process logged the report, and what exception ended it?" do
    assert Koans.Trace.process("02_report") == __
    assert Koans.Trace.exception("02_report") == __
  end

  koan "Read koans/review/02_notifier.ex. Write :fine, or the line number of the bug." do
    verdict("02_notifier.ex", __, "cf9afaa819", "3e5cae055d")
  end

  koan "Fix the bug in koans/review/02_notifier.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch02.Notifier, Review.Ch02.Notifier)
  end

  koan "Read koans/review/02_job_runner.ex. Write :fine, or the line number of the bug." do
    verdict("02_job_runner.ex", __, "38ba2c49f2,637033f4c6,d59e44fcfe,d958f817ed", "265677b831")
  end

  koan "Fix the bug in koans/review/02_job_runner.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch02.JobRunner, Review.Ch02.JobRunner)
  end

  koan "Read koans/review/02_asker.ex. Write :fine, or the line number of the bug." do
    verdict("02_asker.ex", __, "bd34ee83d6,c2d241fe17,dd1d39b05b", "132e3a6f02")
  end

  koan "Fix the bug in koans/review/02_asker.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch02.Asker, Review.Ch02.Asker)
  end

  koan "Read koans/review/02_worker_stop.ex. Write :fine, or the line number of the bug." do
    verdict("02_worker_stop.ex", __, "8b91da40a4,badaf31ea3", "9d9c24bf82")
  end

  koan "Fix the bug in koans/review/02_worker_stop.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch02.WorkerStop, Review.Ch02.WorkerStop)
  end

  koan "Read koans/review/02_supervised_task.ex. Write :fine, or the line number of the bug." do
    verdict("02_supervised_task.ex", __, "0be6617dff", "3d28db7775")
    run_checks(Checks.Ch02.SupervisedTask, Review.Ch02.SupervisedTask)
  end

  defp answer_pings do
    receive do
      {:ping, from} ->
        send(from, :pong)
        answer_pings()
    end
  end

  defp trap_and_wait(test) do
    Process.flag(:trap_exit, true)
    send(test, :trapping)

    receive do
      :never -> :ok
    end
  end
end
