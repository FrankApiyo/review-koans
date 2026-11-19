defmodule Verify.TraceTest do
  use ExUnit.Case, async: false

  alias Koans.Trace

  # boom.exs.trace was captured from verify/fixtures/traces/boom.exs with cwd verify/fixtures.
  defp boom(extractor), do: File.cd!("verify/fixtures", fn -> extractor.("boom") end)

  test "read! returns the fixture as captured" do
    assert boom(&Trace.read!/1) =~ ~r/\Aexit 1\n--- stdout\n\n\[error\] GenServer Boom.Board/
  end

  test "exception is the first raised module" do
    assert boom(&Trace.exception/1) == "KeyError"
  end

  test "first_frame is the first course line" do
    assert boom(&Trace.first_frame/1) == {"traces/boom.exs", 9}
  end

  test "frames lists each course line once, in order" do
    assert boom(&Trace.frames/1) == [
             {"traces/boom.exs", 9},
             {"traces/boom.exs", 21},
             {"traces/boom.exs", 35}
           ]
  end

  test "reports counts the error reports" do
    assert boom(&Trace.reports/1) == 2
  end

  test "last_message is the first report's message" do
    assert boom(&Trace.last_message/1) == ~s(%{"cell" => "b2", "event" => "mark"})
  end

  test "process is the registered name from the first report" do
    assert boom(&Trace.process/1) == "Boom.Board"
  end

  test "event is the event name in the first event message" do
    assert boom(&Trace.event/1) == "mark"
  end

  defp with_trace(text, extractor) do
    dir =
      Path.join(System.tmp_dir!(), "review-koans-trace-#{System.unique_integer([:positive])}")

    File.mkdir_p!(Path.join(dir, "traces"))
    on_exit(fn -> File.rm_rf!(dir) end)
    File.write!(Path.join(dir, "traces/inline.exs.trace"), text)
    File.cd!(dir, fn -> extractor.("inline") end)
  end

  test "exception skips the caller's exit wrapper" do
    exited = "** (exit) exited in: GenServer.call(Board, :mark, 5000)\n    ** (EXIT) :boom\n"

    assert with_trace(exited, &Trace.exception/1) == nil
  end

  test "last_message leaves out the caller" do
    called = "Last message (from #PID<0.94.0>): {:bump, \"two\"}\n"

    assert with_trace(called, &Trace.last_message/1) == ~s({:bump, "two"})
  end

  test "stop_reason is the first report's stop line, without its marker" do
    stopped = """
    [error] GenServer Counter terminating
    ** (stop) bad return value: {:ok, 1}
    Last message (from #PID<0.94.0>): :incr
    [error] GenServer :bob terminating
    ** (stop) exited in: GenServer.call(:alice, :balance, 300)
    """

    assert with_trace(stopped, &Trace.stop_reason/1) == "bad return value: {:ok, 1}"
  end

  test "stop_reason is nil without a stop line, and raises on a pid" do
    assert with_trace("** (exit) :boom\n", &Trace.stop_reason/1) == nil

    assert_raise ArgumentError, ~r/changes on every capture/, fn ->
      with_trace(
        "** (stop) exited in: GenServer.call(#PID<0.1.0>, :x, 5000)\n",
        &Trace.stop_reason/1
      )
    end
  end

  test "init_failure is the module and line of the first init frame in a start error" do
    start_error = """
    {:error,
     {:shutdown,
      {:failed_to_start_child, Shop.Cache,
       {{:badmatch, {:error, :econnrefused}},
        [
          {Shop.Cache, :init, 1, [file: ~c"traces/inline.exs", line: 8]},
          {:gen_server, :init_it, 2, [file: ~c"gen_server.erl", line: 2276]}
        ]}}}}
    """

    assert with_trace(start_error, &Trace.init_failure/1) == {"Shop.Cache", 8}
  end

  test "init_failure skips runtime init frames and is nil without a course one" do
    runtime_only = """
    {Supervisor.Default, :init, 1, [file: ~c"lib/supervisor/default.ex", line: 7]},
    {:gen_server, :init_it, 2, [file: ~c"gen_server.erl", line: 2276]}
    """

    assert with_trace(runtime_only, &Trace.init_failure/1) == nil
  end

  test "an answer holding a pid, ref, port or LiveView id raises" do
    varying = """
    [error] GenServer #PID<0.512.0> terminating
    Last message: {:ping, #PID<0.94.0>}
    Last message: %{"event" => "phx-GHk3x"}
    """

    assert with_trace(varying, &Trace.process/1) == "GenServer"

    for extractor <- [&Trace.last_message/1, &Trace.event/1] do
      assert_raise ArgumentError, ~r/changes on every capture/, fn ->
        with_trace(varying, extractor)
      end
    end
  end
end
