defmodule Checks.Ch05.EtsCalls do
  @moduledoc """
  Records which `:ets` functions a function calls in the calling process, so a check can tell
  one atomic table call from a read followed by a separate write without racing anything.

  The tracer is a separate process, so no trace message lands in the caller's mailbox. Tracing
  runs in a trace session of its own, so it never meets another tracer's flags, and OTP
  destroys a session once its handle is garbage collected, so a caller killed mid-call leaves
  no tracing behind.
  """

  @spec during((-> result)) :: {result, [{atom(), arity()}]} when result: term()
  def during(fun) do
    caller = self()
    collector = spawn(fn -> collect(caller, Process.monitor(caller), []) end)
    session = :trace.session_create(__MODULE__, collector, [])
    true = :trace.function(session, {:ets, :_, :_}, true, [:global]) > 0
    1 = :trace.process(session, caller, true, [:call])
    outcome = run(fun)
    1 = :trace.process(session, caller, false, [:call])
    calls = delivered(session, caller, collector)
    true = :trace.session_destroy(session)
    returned(outcome, calls)
  end

  @doc "True when a plain `insert` follows another table call, so the write acts on an earlier read."
  @spec write_after_read?([{atom(), arity()}]) :: boolean()
  def write_after_read?([_first | later]), do: Enum.any?(later, &plain_insert?/1)
  def write_after_read?([]), do: false

  defp plain_insert?({:insert, _arity}), do: true
  defp plain_insert?(_call), do: false

  defp run(fun) do
    {:returned, fun.()}
  catch
    kind, reason -> {kind, reason, __STACKTRACE__}
  end

  # Trace messages can lag behind the caller; trace_delivered says when every one has arrived.
  defp delivered(session, caller, collector) do
    ref = :trace.delivered(session, caller)

    receive do
      {:trace_delivered, ^caller, ^ref} -> send(collector, {:dump, caller})
    end

    receive do
      {:ets_calls, ^collector, calls} -> calls
    end
  end

  defp returned({:returned, value}, calls), do: {value, calls}
  defp returned({kind, reason, stack}, _calls), do: :erlang.raise(kind, reason, stack)

  defp collect(caller, ref, calls) do
    receive do
      {:trace, ^caller, :call, {:ets, function, args}} ->
        collect(caller, ref, [{function, length(args)} | calls])

      {:dump, ^caller} ->
        send(caller, {:ets_calls, self(), Enum.reverse(calls)})

      {:DOWN, ^ref, :process, ^caller, _reason} ->
        :ok
    end
  end
end
