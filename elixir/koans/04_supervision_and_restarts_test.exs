defmodule Koans.Ch04.SupervisionAndRestartsTest do
  @moduledoc ~S"""
  Look for: a child listed before a sibling its `init` calls; a sibling's pid kept from
  `init` under a strategy that restarts the sibling alone; the default `:permanent` on work
  that runs once; an `init` that crashes when a call in it fails; and code that expects a
  restarted process to keep its state.

  Why it bites: while the database is down the app will not boot, health check included.
  After a producer restarts, every event goes to a dead pid. A finished warm-up job is
  restarted until its supervisor gives up, which the one above restarts if `:permanent`.

  Review habit: Read for what is missing: a `restart:` option, an `{:error, _}` branch, a
  sibling that has to start first. In a trace, start from the first app frame. OTP documents
  these rules. A supervisor starts its children in list order, one start returning before the
  next begins, and stops them in reverse. A restarted child starts again from `init`.
  `:permanent` restarts on any exit, `:transient` only on a reason other than `:normal`,
  `:shutdown` or `{:shutdown, _}`, and `:temporary` never. When a child is to be restarted,
  `:one_for_one` restarts only it, `:rest_for_one` also the children after it, and
  `:one_for_all` every child. After more than `max_restarts` restarts in `max_seconds`, the
  supervisor stops its children and exits with `:shutdown`; Elixir's `Supervisor` defaults to
  3 in 5 seconds, Erlang's `supervisor` to 1 in 5. A crash in `init` fails the child's start,
  so the tree does not boot; a crash in `handle_continue` comes after the start returned.

  A common mistake: `:one_for_all` so a consumer gets the restarted producer's pid; a
  consumer crash then restarts the producer too, and its state is lost. Put the producer
  first under `:rest_for_one`, or have the consumer look the producer up by name on each
  call. Raising `max_restarts` only lets a job that is restarted after every stop run more
  times, and catching the exit in a cache's `init` boots it empty.

  Read more: https://hexdocs.pm/elixir/1.19.5/Supervisor.html,
  https://www.erlang.org/doc/apps/stdlib/supervisor.html,
  https://www.erlang.org/doc/system/sup_princ.html
  """
  use Koans

  alias Course.Ch04.Crashy

  koan "A child is stopped with :boom each time it starts. How many times does its supervisor restart it before giving up, and with what reason does the supervisor exit?" do
    {:ok, {restarts, reason}} = Koans.Hidden.isolated(&crash_until_the_supervisor_exits/0)

    assert restarts == __
    assert reason == __
  end

  koan "A :transient child stops with :normal, then with {:shutdown, :drained}, then with :boom. After each, is it left stopped (:undefined) or restarted?" do
    spec = Supervisor.child_spec({Crashy, {:job, self()}}, restart: :transient)
    {:ok, sup} = Supervisor.start_link([spec], strategy: :one_for_one)

    assert child_after_stop(sup, :normal) == __
    {:ok, _pid} = Supervisor.restart_child(sup, :job)
    assert child_after_stop(sup, {:shutdown, :drained}) == __
    {:ok, _pid} = Supervisor.restart_child(sup, :job)
    assert is_pid(child_after_stop(sup, :boom)) == __
  end

  koan "A counter is bumped twice, stops with :boom, and is restarted. What does the next bump return?" do
    {:ok, _sup} = Supervisor.start_link([{Crashy, {:counter, self()}}], strategy: :one_for_one)
    counter = started(:counter)
    1 = Crashy.bump(counter)
    2 = Crashy.bump(counter)
    Crashy.stop_with(counter, :boom)
    restarted = started(:counter)

    assert Crashy.bump(restarted) == __
  end

  koan "A supervisor has children :a, :b and :c, in that order, and :b stops with :boom. Which children get a new pid under each strategy?" do
    assert restarted_when_b_stops(:one_for_one) == __
    assert restarted_when_b_stops(:rest_for_one) == __
    assert restarted_when_b_stops(:one_for_all) == __
  end

  koan "Read traces/04_cache_init.exs.trace. Which module's init failed, at which line, and what exception stopped it?" do
    assert Koans.Trace.init_failure("04_cache_init") == __
    assert Koans.Trace.exception("04_cache_init") == __
  end

  koan "Read traces/04_poller.exs.trace. How many crash reports did the poller log before its supervisor gave up, and at which course line did it crash?" do
    assert Koans.Trace.reports("04_poller") == __
    assert Koans.Trace.first_frame("04_poller") == __
  end

  koan "Read koans/review/04_tree.ex; Cache and Store in lib/course/04_cache_store.ex are correct as written. Write :fine, or the line number of the bug." do
    verdict("04_tree.ex", __, "4aeedbc32d,e37ed29106", "7efb42c577")
  end

  koan "Fix the bug in koans/review/04_tree.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch04.Tree, Review.Ch04.Tree)
  end

  koan "Read koans/review/04_pipeline.ex; Producer and Consumer in lib/course/04_pipeline_workers.ex work as their docs describe. Write :fine, or the line number of the bug." do
    verdict("04_pipeline.ex", __, "9b0e083183,acd7b64e9f", "af34677a0b")
  end

  koan "Fix the bug in koans/review/04_pipeline.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch04.Pipeline, Review.Ch04.Pipeline)
  end

  koan "Read koans/review/04_warmup.ex. Write :fine, or the line number of the bug." do
    verdict("04_warmup.ex", __, "8f60b139d8,c9a58d7f75", "47b380da14")
  end

  koan "Fix the bug in koans/review/04_warmup.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch04.Warmup, Review.Ch04.Warmup)
  end

  koan "Read koans/review/04_price_cache.ex. Write :fine, or the line number of the bug." do
    verdict("04_price_cache.ex", __, "06bcd0c600,2f25780875,9ca504c840,caa5e5f424,ced4ca7354,fa85c0c8c3", "566b81c9c6")
  end

  koan "Fix the bug in koans/review/04_price_cache.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch04.PriceCache, Review.Ch04.PriceCache)
  end

  koan "Read koans/review/04_uploads.ex. Write :fine, or the line number of the bug." do
    verdict("04_uploads.ex", __, "d1029e72a1", "38fcf3ebdc")
    run_checks(Checks.Ch04.Uploads, Review.Ch04.Uploads)
  end

  # Unlinked and monitored, so the supervisor's exit arrives as a :DOWN rather than killing
  # this process. Each stop ends in either a restart or the supervisor's exit, never both.
  defp crash_until_the_supervisor_exits do
    children = [{Crashy, {:worker, self()}}]
    {:ok, sup} = Supervisor.start_link(children, strategy: :one_for_one, max_seconds: 3600)
    Process.unlink(sup)
    ref = Process.monitor(sup)
    stop_and_count(sup, ref, started(:worker), 0)
  end

  defp stop_and_count(sup, ref, worker, restarts) do
    Crashy.stop_with(worker, :boom)

    receive do
      {:started, :worker, restarted} -> stop_and_count(sup, ref, restarted, restarts + 1)
      {:DOWN, ^ref, :process, ^sup, reason} -> {restarts, reason}
    end
  end

  defp child_after_stop(sup, reason) do
    [{:job, pid, :worker, _modules}] = Supervisor.which_children(sup)
    Crashy.stop_with(pid, reason)
    true = Koans.Hidden.wait_until(fn -> child_pid(sup, :job) != pid end)
    child_pid(sup, :job)
  end

  defp restarted_when_b_stops(strategy) do
    children = for id <- [:a, :b, :c], do: {Crashy, {id, self()}}
    {:ok, sup} = Supervisor.start_link(children, strategy: strategy)
    before = child_pids(sup)
    Crashy.stop_with(before[:b], :boom)
    true = Koans.Hidden.wait_until(fn -> child_pids(sup)[:b] != before[:b] end)
    later = child_pids(sup)
    :ok = Supervisor.stop(sup)
    for id <- [:a, :b, :c], later[id] != before[id], do: id
  end

  defp started(id) do
    receive do
      {:started, ^id, pid} -> pid
    end
  end

  defp child_pid(sup, id), do: child_pids(sup)[id]

  defp child_pids(sup) do
    Map.new(Supervisor.which_children(sup), fn {id, pid, _type, _modules} -> {id, pid} end)
  end
end
