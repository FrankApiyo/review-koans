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
