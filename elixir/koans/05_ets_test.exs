defmodule Koans.Ch05.EtsTest do
  @moduledoc ~S"""
  Look for: a `lookup` or `member` check followed by a separate write; a table written by
  processes other than its owner while it is `:protected`; a table created by whichever
  process calls first; and a match spec's guard at a boundary, or a `select_delete` whose
  body is not `true`.

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

  A common mistake: keeping a `lookup` as the guard in front of a plain `insert`. Two callers
  both pass it before either writes, and the second overwrites the first. Use `insert_new` or
  `update_counter` with a default row, or send every write through the owner. Create a shared
  table in the `init` of a supervised process, not on first use.

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

    assert read == __
    assert write == __
    assert :ets.info(table, :protection) == __
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

    assert gone == __
    assert raised(fn -> :ets.lookup(:sessions, "s1") end) == __
  end

  koan "{\"ada\", :admin} is inserted, then {\"ada\", :editor} twice, into a table of each type. What does a lookup of \"ada\" return for each, and which key does an :ordered_set of \"cy\", \"ada\" and \"bo\" give first?" do
    assert roles(:set) == __
    assert roles(:bag) == __
    assert roles(:duplicate_bag) == __

    sorted = :ets.new(:names, [:ordered_set])
    true = :ets.insert(sorted, [{"cy"}, {"ada"}, {"bo"}])
    assert :ets.first(sorted) == __
  end

  koan "Two workers each look up job 42, then insert a claim if the job looked free. Scripted in one process, both look before either writes. What does each report, and whose claim is left? Then two insert_new calls for job 42." do
    table = :ets.new(:jobs, [:set, :public])
    a_sees = :ets.lookup(table, 42)
    b_sees = :ets.lookup(table, 42)
    a = claim_if_free(table, a_sees, :worker_a)
    b = claim_if_free(table, b_sees, :worker_b)

    assert {a, b} == __
    assert :ets.lookup(table, 42) == __

    fresh = :ets.new(:jobs, [:set, :public])
    assert :ets.insert_new(fresh, {42, :worker_a}) == __
    assert :ets.insert_new(fresh, {42, :worker_b}) == __
    assert :ets.lookup(fresh, 42) == __
  end

  koan "update_counter adds to a counter in place. What does it raise for a key that is not in the table, what is in the table afterwards, and what do two calls with the default row {\"/home\", 0} return?" do
    table = :ets.new(:hits, [:set, :public])

    assert raised(fn -> :ets.update_counter(table, "/home", 1) end) == __
    assert :ets.lookup(table, "/home") == __

    first = :ets.update_counter(table, "/home", 1, {"/home", 0})
    second = :ets.update_counter(table, "/home", 1, {"/home", 0})
    assert {first, second} == __
    assert :ets.lookup_element(table, "/about", 2, 0) == __
  end

  koan "Read traces/05_sessions.exs.trace. Which process stopped first, and on which message? Then which course lines does the trace show, in order?" do
    assert Koans.Trace.process("05_sessions") == __
    assert Koans.Trace.last_message("05_sessions") == __

    assert Koans.Trace.frames("05_sessions") ==
             __
  end

  koan "Read koans/review/05_jobs.ex. Write :fine, or the line number of the bug." do
    verdict("05_jobs.ex", __, "00fdb748d3,f88a27aa33", "c1887babb0")
  end

  koan "Fix the bug in koans/review/05_jobs.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch05.Jobs, Review.Ch05.Jobs)
  end

  koan "Read koans/review/05_rate_limit.ex. Write :fine, or the line number of the bug." do
    verdict("05_rate_limit.ex", __, "0c8c3504e0,7f86d2dece,a7a51dc01d,ae730b77e5,bdf1bfb3dd,eb888faec2", "fe2d4aa164")
  end

  koan "Fix the bug in koans/review/05_rate_limit.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch05.RateLimit, Review.Ch05.RateLimit)
  end

  koan "Read koans/review/05_flags.ex. Write :fine, or the line number of the bug." do
    verdict("05_flags.ex", __, "23da8e2be9,4f5d324f1c,5cd879cc0f,643ac29eb6,667a8f0466,6e41a1b0d6,791f938349,b1c8d073c1,b38b31b174", "9de105376e")
  end

  koan "Fix the bug in koans/review/05_flags.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch05.Flags, Review.Ch05.Flags)
  end

  koan "Read koans/review/05_expiry.ex. Write :fine, or the line number of the bug." do
    verdict("05_expiry.ex", __, "ab63ae3489", "8799799015")
  end

  koan "Fix the bug in koans/review/05_expiry.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch05.Expiry, Review.Ch05.Expiry)
  end

  koan "Read koans/review/05_hits.ex. Write :fine, or the line number of the bug." do
    verdict("05_hits.ex", __, "662be2a99e", "8f36e5c023")
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
