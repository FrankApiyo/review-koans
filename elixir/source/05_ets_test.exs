defmodule Koans.Ch05.EtsTest do
  @moduledoc ~S"""
  Look for: a `lookup` or `member` check followed by a separate write; a table written by
  processes other than its owner while it is `:protected`; a table created by whichever
  process calls first; a match spec's guard at a boundary; a `select_delete` body not `true`.

  Why it bites: two workers both see a job as free, and both process it. A rate limiter
  raises `ArgumentError` on every request from its first deploy. Feature flags vanish when
  the request that happened to create their table ends.

  Review habit: Ask what happens with two at once. OTP documents each update of a single
  object as atomic and isolated, but nothing holds between two calls: another process can
  write in the gap. `insert_new` writes only if the key is absent, and `update_counter` adds
  in place, so put the decision in the call that writes. A table belongs to the process that
  created it and is deleted when that process dies, unless it has an `:heir`; OTP's docs
  do not say whether that happens before or after the owner's `:DOWN`. `:protected`, the
  default, lets any process read and only the owner write; `:public` lets any process write;
  `:private` keeps both to the owner. `read_concurrency` and `write_concurrency` are
  performance tuning: they change neither access nor atomicity. A `:set` keeps one object
  per key, a `:bag` each distinct object, a `:duplicate_bag` every copy, and an
  `:ordered_set` walks its keys in term order. `select_delete` deletes only the rows for which
  the match spec returns `true`.

  A common mistake: acting on a `lookup` or `member` check in front of the write. Two callers
  both pass it before either writes. Let the write decide alone: `insert_new` and its result,
  `update_counter` with a default row, or one call in which the owner checks and writes. The
  course asks for one atomic `insert_new` and no read before it, as its own choice: a
  `member` check ahead of an `insert_new` you honour is no race, only redundant.
  Create a shared table in the `init` of a supervised process, never on first use.

  Read more: https://www.erlang.org/doc/apps/stdlib/ets.html,
  https://www.erlang.org/doc/apps/erts/match_spec.html
  """
  use Koans

  koan "The test process creates a table with no access option and inserts {\"tea\", 3}. Another process reads \"tea\", then tries to write {\"tea\", 4}. What does it read, what does the write raise, and what access did the table get?" do
    table = :ets.new(:prices, [:set])
    true = :ets.insert(table, {"tea", 3})

    {read, write} =
      Task.await(
        Task.async(fn ->
          {:ets.lookup(table, "tea"), raised(fn -> :ets.insert(table, {"tea", 4}) end)}
        end)
      )

    assert read == _a([{"tea", 3}])
    assert write == _a(ArgumentError)
    assert :ets.info(table, :protection) == _a(:protected)
  end

  koan "A process creates a named :public table, :sessions, and exits. After its :DOWN, does the table go too (wait_until gives true once it is gone, false if it never goes), and what does a lookup in it raise?" do
    {owner, ref} =
      spawn_monitor(fn ->
        :sessions = :ets.new(:sessions, [:named_table, :public])
        true = :ets.insert(:sessions, {"s1", "ada"})
      end)

    receive do
      {:DOWN, ^ref, :process, ^owner, :normal} -> :ok
    end

    gone = Koans.Hidden.wait_until(fn -> :ets.whereis(:sessions) == :undefined end)

    assert gone == _a(true)
    assert raised(fn -> :ets.lookup(:sessions, "s1") end) == _a(ArgumentError)
  end

  koan "{\"ada\", :admin} is inserted, then {\"ada\", :editor} twice, into a table of each type. What does a lookup of \"ada\" return for each, and which key does an :ordered_set of \"cy\", \"ada\" and \"bo\" give first?" do
    assert roles(:set) == _a([{"ada", :editor}])
    assert roles(:bag) == _a([{"ada", :admin}, {"ada", :editor}])
    assert roles(:duplicate_bag) == _a([{"ada", :admin}, {"ada", :editor}, {"ada", :editor}])

    sorted = :ets.new(:names, [:ordered_set])
    true = :ets.insert(sorted, [{"cy"}, {"ada"}, {"bo"}])
    assert :ets.first(sorted) == _a("ada")
  end

  koan "Two workers each look up job 42, then insert a claim if the job looked free. Scripted in one process, both look before either writes. What does each report, and whose claim is left? Then two insert_new calls for job 42." do
    table = :ets.new(:jobs, [:set, :public])
    a_sees = :ets.lookup(table, 42)
    b_sees = :ets.lookup(table, 42)
    a = claim_if_free(table, a_sees, :worker_a)
    b = claim_if_free(table, b_sees, :worker_b)

    assert {a, b} == _a({:claimed, :claimed})
    assert :ets.lookup(table, 42) == _a([{42, :worker_b}])

    fresh = :ets.new(:jobs, [:set, :public])
    assert :ets.insert_new(fresh, {42, :worker_a}) == _a(true)
    assert :ets.insert_new(fresh, {42, :worker_b}) == _a(false)
    assert :ets.lookup(fresh, 42) == _a([{42, :worker_a}])
  end

  koan "update_counter adds to a counter in place. What does it raise for a key that is not in the table, what is in the table afterwards, and what do two calls with the default row {\"/home\", 0} return?" do
    table = :ets.new(:hits, [:set, :public])

    assert raised(fn -> :ets.update_counter(table, "/home", 1) end) == _a(ArgumentError)
    assert :ets.lookup(table, "/home") == _a([])

    first = :ets.update_counter(table, "/home", 1, {"/home", 0})
    second = :ets.update_counter(table, "/home", 1, {"/home", 0})
    assert {first, second} == _a({1, 2})
    assert :ets.lookup_element(table, "/about", 2, 0) == _a(0)
  end

  koan "Read traces/05_sessions.exs.trace. Which process stopped first, and on which message? Then which course lines does the trace show, in order?" do
    assert Koans.Trace.process("05_sessions") == _a("SessionStore")
    assert Koans.Trace.last_message("05_sessions") == _a("{:\"$gen_cast\", :reload}")

    assert Koans.Trace.frames("05_sessions") ==
             _a([
               {"traces/05_sessions.exs", 18},
               {"traces/05_sessions.exs", 8},
               {"traces/05_sessions.exs", 23}
             ])
  end

  koan "Read koans/review/05_jobs.ex. Write :fine, or the line number of the bug." do
    verdict("05_jobs.ex", _a(13))
  end

  koan "Fix the bug in koans/review/05_jobs.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch05.Jobs, Review.Ch05.Jobs)
  end

  koan "Read koans/review/05_rate_limit.ex. Write :fine, or the line number of the bug." do
    verdict("05_rate_limit.ex", _a(22))
  end

  koan "Fix the bug in koans/review/05_rate_limit.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch05.RateLimit, Review.Ch05.RateLimit)
  end

  koan "Read koans/review/05_flags.ex. Write :fine, or the line number of the bug." do
    verdict("05_flags.ex", _a(35))
  end

  koan "Fix the bug in koans/review/05_flags.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch05.Flags, Review.Ch05.Flags)
  end

  koan "Read koans/review/05_expiry.ex. Write :fine, or the line number of the bug." do
    verdict("05_expiry.ex", _a(10))
  end

  koan "Fix the bug in koans/review/05_expiry.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch05.Expiry, Review.Ch05.Expiry)
  end

  koan "Read koans/review/05_hits.ex. Write :fine, or the line number of the bug." do
    verdict("05_hits.ex", _a(:fine))
    run_checks(Checks.Ch05.Hits, Review.Ch05.Hits)
  end

  defp raised(fun) do
    fun.()
    :nothing_raised
  rescue
    error -> error.__struct__
  end

  defp roles(type) do
    table = :ets.new(:roles, [type])
    true = :ets.insert(table, {"ada", :admin})
    true = :ets.insert(table, {"ada", :editor})
    true = :ets.insert(table, {"ada", :editor})
    :ets.lookup(table, "ada")
  end

  defp claim_if_free(table, [], worker) do
    true = :ets.insert(table, {42, worker})
    :claimed
  end

  defp claim_if_free(_table, _seen, _worker), do: :busy
end
