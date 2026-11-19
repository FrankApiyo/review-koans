defmodule Koans.Formatter do
  use GenServer

  alias Koans.Footer

  @initial %{passed: 0, ran: 0, failures: [], finished: []}
  @timed_out "A hidden case did not finish within 5 seconds."
  @process_exited "A hidden case stopped the koan: the test process exited."

  @impl true
  def init(_opts), do: {:ok, @initial}

  @impl true
  def handle_cast({:test_finished, %ExUnit.Test{state: {kind, _}}}, state)
      when kind in [:excluded, :skipped] do
    {:noreply, state}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: nil, tags: %{doctest: _}}}, state) do
    {:noreply, state}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: nil} = test}, state) do
    {:noreply,
     %{state | passed: state.passed + 1, ran: state.ran + 1, finished: finish(state, test, "ok")}}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:failed, [first | _]}} = test}, state) do
    record_failure(state, test, first)
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:invalid, module}} = test}, state) do
    record_failure(state, test, invalid_failure(module))
  end

  def handle_cast({:test_finished, _test}, state) do
    {:noreply, %{state | ran: state.ran + 1}}
  end

  def handle_cast({:suite_finished, _times}, state) do
    total = Footer.total(System.get_env("KOANS_DIR", "koans"))
    failure = Footer.earliest(state.failures)

    footer =
      Footer.render(%{passed: state.passed, total: total, ran: state.ran, failure: failure})

    IO.puts("\n" <> footer)
    if Koans.Setup.verify?(), do: print_verify_lines(state.finished, failure)
    {:noreply, state}
  end

  def handle_cast(_event, state), do: {:noreply, state}

  defp record_failure(state, test, {kind, reason, _} = raw) do
    failure = build_failure(test, raw)
    finished = finish(state, test, Footer.kind(kind, reason))

    {:noreply,
     %{state | ran: state.ran + 1, failures: [failure | state.failures], finished: finished}}
  end

  defp finish(state, test, kind) do
    [{kind, Path.relative_to_cwd(test.tags.file), test.tags.line} | state.finished]
  end

  defp print_verify_lines(finished, failure) do
    finished
    |> Enum.sort_by(fn {_kind, file, line} -> {file, line} end)
    |> Enum.each(fn {kind, file, line} -> IO.puts("KOANS-TEST #{kind} #{file}:#{line}") end)

    case failure do
      nil -> IO.puts("KOANS-RESULT ok")
      failure -> IO.puts("KOANS-RESULT #{failure.kind} #{failure.path}:#{failure.line}")
    end
  end

  defp invalid_failure(%{state: {:failed, [first | _]}}), do: first

  defp invalid_failure(other),
    do: {:error, %RuntimeError{message: "invalid: #{inspect(other)}"}, []}

  defp build_failure(test, {kind, reason, stacktrace}) do
    {file, line} = Footer.location(test, reason, stacktrace)
    {text, write} = text_and_write(test.tags[:review_module], kind, reason, stacktrace)

    %{
      path: Path.relative_to_cwd(file),
      line: line,
      meditation: to_string(test.tags[:meditation]),
      diff: text,
      write: write,
      kind: Footer.kind(kind, reason),
      sort_key: {test.tags.file, test.tags.line}
    }
  end

  # A fix koan names the review file to write and never shows a check's diff or input.
  defp text_and_write(review, kind, reason, stacktrace) do
    case {reason, review && stopped(kind, reason)} do
      {%Koans.HiddenCase{} = error, _} -> {Exception.message(error), error.review_path}
      {_, text} when is_binary(text) -> {text, Koans.Hidden.review_path(review)}
      _ -> {failure_text(kind, reason, stacktrace), nil}
    end
  end

  defp stopped(_kind, %ExUnit.TimeoutError{}), do: @timed_out
  defp stopped({:EXIT, _pid}, _reason), do: @process_exited
  defp stopped(:exit, _reason), do: @process_exited
  defp stopped(_kind, _reason), do: nil

  defp failure_text(kind, reason, stacktrace) do
    case Footer.blank(reason) do
      %Koans.Blank{message: message} -> message
      nil -> diff(kind, reason, stacktrace)
    end
  end

  defp diff(_kind, %ExUnit.AssertionError{} = error, _stacktrace) do
    case assertion_lines(error) do
      [] ->
        error.message

      lines when error.right == :ex_unit_no_meaningful_value ->
        Enum.join(lines ++ [first_line(error.message)], "\n")

      lines ->
        Enum.join(lines, "\n")
    end
  end

  defp diff(:error, reason, stacktrace),
    do: Exception.message(Exception.normalize(:error, reason, stacktrace))

  defp diff(:throw, reason, _stacktrace), do: "throw: " <> inspect(reason)
  defp diff(_exit, reason, _stacktrace), do: Exception.format_exit(reason)

  defp first_line(message), do: message |> String.split("\n") |> hd()

  defp assertion_lines(error) do
    [
      labelled("code: ", error.expr, &Macro.to_string/1),
      labelled("left:  ", error.left, &pretty/1),
      labelled("right: ", error.right, &pretty/1)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp labelled(_label, :ex_unit_no_meaningful_value, _fun), do: nil
  defp labelled(label, value, fun), do: label <> fun.(value)

  defp pretty(value), do: inspect(value, pretty: true)
end
