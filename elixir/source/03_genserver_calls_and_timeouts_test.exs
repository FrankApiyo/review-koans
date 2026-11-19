defmodule Koans.Ch03.GenServerCallsAndTimeoutsTest do
  @moduledoc ~S"""
  Look for: a decision made in the caller on a value an earlier call returned; slow work
  inside a callback; replies deferred with `{:noreply, ...}` that are lost or kept after use;
  `from` used as a key; a `Process.monitor` with no `:DOWN` clause; and a server that calls
  itself, or calls a server that calls it back.

  Why it bites: two customers both read the last unit and both buy it. One slow refresh
  holds the server, so every caller queues behind it until its call times out. A registry
  that monitors clients but never handles `:DOWN` grows with every client that ends.

  Review habit: Ask what happens with two at once. A server runs one callback at a time, so
  a check and the act that depends on it are safe together only inside one callback; between
  two calls, another caller's request can run. For each callback, ask who else waits while
  it runs. A `from` kept for `GenServer.reply/2` is answered once, then dropped. `from` holds
  the caller's pid and a tag that is new on every call; the tag's shape is OTP's internal,
  so key by the pid. A monitor delivers one `:DOWN`, and a clause has to handle it.
  `{:continue, ...}` returned from `init` runs before the server takes any message.

  A common mistake: catching a call's timeout and treating the request as cancelled. The
  caller exits with `{:timeout, ...}`, but the server keeps working on it. Since OTP 24 a
  reply that arrives after `GenServer.call` gave up is dropped rather than left in the
  caller's mailbox: OTP's `gen_server:call` docs say so, Elixir's `GenServer.call` docs still
  describe the older behaviour, and it holds for calls, not hand-made requests (chapter 1).
  Move slow work into a `Task` that sends its result back to `handle_info`. OTP's
  `gen_server:call` refuses a call to the caller's own server: the caller exits with
  `:calling_self`. Two servers that call each other each wait for the other until one call
  times out, or for ever with `:infinity`.

  Read more: https://hexdocs.pm/elixir/1.19.5/GenServer.html,
  https://hexdocs.pm/elixir/1.19.5/Task.html,
  https://www.erlang.org/doc/apps/stdlib/gen_server.html
  """
  use Koans

  koan "A call gives up after 10 ms while the server is still busy with it. Name the reason the caller exits with, then what is in its mailbox once the server has replied late." do
    server = start_supervised!(Course.Ch03.Slow)
    {reason, {GenServer, :call, _args}} = catch_exit(GenServer.call(server, :slow, 10))
    send(server, :release)
    :pong = GenServer.call(server, :ping)

    assert reason == _a(:timeout)
    assert Process.info(self(), :messages) == _a({:messages, []})
  end

  koan "A call and two casts go to a name nobody registered and to a process that has exited. Name the call's exit reason and the timeout it used, then what each cast returns." do
    {reason, {GenServer, :call, [:no_such_server, :ping, timeout]}} =
      catch_exit(GenServer.call(:no_such_server, :ping))

    dead = spawn(fn -> :ok end)
    ref = Process.monitor(dead)

    receive do
      {:DOWN, ^ref, :process, ^dead, _reason} -> :ok
    end

    assert reason == _a(:noproc)
    assert timeout == _a(5000)
    assert GenServer.cast(:no_such_server, :ping) == _a(:ok)
    assert GenServer.cast(dead, :ping) == _a(:ok)
  end

  koan "Read traces/03_cart_self_call.exs.trace. Name the file and line of the first course frame, then the last message the server took." do
    assert Koans.Trace.first_frame("03_cart_self_call") ==
             _a({"traces/03_cart_self_call.exs", 15})

    assert Koans.Trace.last_message("03_cart_self_call") == _a("{:\"$gen_cast\", {:add, 3}}")
  end

  koan "Read traces/03_bad_return.exs.trace. Which server stopped, which request was it handling, and what does the report's ** (stop) line say stopped it, in the report's own wording?" do
    assert Koans.Trace.process("03_bad_return") == _a("Counter")
    assert Koans.Trace.last_message("03_bad_return") == _a(":incr")
    assert Koans.Trace.stop_reason("03_bad_return") == _a("bad return value: {:ok, 1}")
  end

  koan "Read traces/03_transfer_cycle.exs.trace. Which request was the first server to stop handling, and which two course lines call each other?" do
    assert Koans.Trace.last_message("03_transfer_cycle") == _a("{:deposit, :alice, 10}")

    assert Koans.Trace.frames("03_transfer_cycle") ==
             _a([{"traces/03_transfer_cycle.exs", 18}, {"traces/03_transfer_cycle.exs", 12}])
  end

  koan "Read koans/review/03_stock.ex. Write :fine, or the line number of the bug." do
    verdict("03_stock.ex", _a(27))
  end

  koan "Fix the bug in koans/review/03_stock.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch03.Stock, Review.Ch03.Stock)
  end

  koan "Read koans/review/03_rates.ex. Write :fine, or the line number of the bug." do
    verdict("03_rates.ex", _a(25))
  end

  koan "Fix the bug in koans/review/03_rates.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch03.Rates, Review.Ch03.Rates)
  end

  koan "Read koans/review/03_batcher.ex. Write :fine, or the line number of the bug." do
    verdict("03_batcher.ex", _a(33))
  end

  koan "Fix the bug in koans/review/03_batcher.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch03.Batcher, Review.Ch03.Batcher)
  end

  koan "Read koans/review/03_presence.ex. Write :fine, or the line number of the bug." do
    verdict("03_presence.ex", _a(23))
  end

  koan "Fix the bug in koans/review/03_presence.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch03.Presence, Review.Ch03.Presence)
  end

  koan "Read koans/review/03_registry.ex. Write :fine, or the line number of the bug." do
    verdict("03_registry.ex", _a(23))
  end

  koan "Fix the bug in koans/review/03_registry.ex in place. The hidden checks name what still fails." do
    run_checks(Checks.Ch03.Registry, Review.Ch03.Registry)
  end

  koan "Read koans/review/03_catalog.ex. Write :fine, or the line number of the bug." do
    verdict("03_catalog.ex", _a(:fine))
    run_checks(Checks.Ch03.Catalog, Review.Ch03.Catalog)
  end
end
