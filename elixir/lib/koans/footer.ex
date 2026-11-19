defmodule Koans.Footer do
  @width 80

  @spec render(map()) :: String.t()
  def render(%{passed: passed, total: total, ran: ran, failure: failure}) do
    body(passed, total, ran, failure)
  end

  defp body(passed, total, _ran, %{} = failure) do
    diff = if failure.diff, do: failure.diff <> "\n", else: ""

    meditation =
      failure.meditation
      |> String.split("\n")
      |> Enum.map_join("\n", &("    " <> &1))

    diff <>
      separator("The master says") <>
      "\n#{where(failure)}\n#{meditation}\n" <>
      "#{passed} of #{total} koans answered."
  end

  defp body(passed, total, ran, nil) when ran >= total and passed == total do
    separator("Enlightenment") <>
      "\nAll #{total} koans pass. Start again with: git checkout -- koans/"
  end

  defp body(_passed, _total, 0, nil) do
    "No koan at that line: put the cursor inside a koan, or run the file."
  end

  defp body(passed, total, _ran, nil) do
    "#{passed} of #{total} koans answered. Run the whole suite for the rest."
  end

  defp where(%{write: write} = failure) when is_binary(write) do
    "Write:        #{write}\nExercised by: #{failure.path}:#{failure.line}"
  end

  defp where(failure), do: "Meditate on #{failure.path}:#{failure.line}"

  @spec total(Path.t()) :: non_neg_integer()
  def total(dir) do
    dir
    |> Path.join("*_test.exs")
    |> Path.wildcard()
    |> Enum.map(fn file ->
      ~r/^\s*koan\s+"/m |> Regex.scan(File.read!(file)) |> length()
    end)
    |> Enum.sum()
  end

  @spec kind(atom(), term()) :: String.t()
  def kind(_kind, %ExUnit.TimeoutError{}), do: "timeout"

  def kind(kind, reason) do
    case {find_blank(reason), kind, reason} do
      {%Koans.Blank{}, _, _} -> "Koans.Blank"
      {_, :error, %{__struct__: module}} -> inspect(module)
      {_, :error, _} -> "error"
      {_, :exit, _} -> "exit"
      {_, other, _} -> to_string(other)
    end
  end

  @spec location(ExUnit.Test.t(), term(), Exception.stacktrace()) :: {String.t(), pos_integer()}
  def location(test, error, stacktrace) do
    case find_blank(error) do
      %Koans.Blank{file: file, line: line} -> {file, line}
      nil -> from_stacktrace(test, error, stacktrace)
    end
  end

  defp from_stacktrace(test, error, stacktrace) do
    file = test.tags.file

    frame_line =
      if match?(%ExUnit.TimeoutError{}, error) do
        nil
      else
        Enum.find_value(stacktrace, fn
          {_m, _f, _a, loc} when is_list(loc) ->
            if same_file?(loc[:file], file), do: loc[:line]

          _ ->
            nil
        end)
      end

    {file, frame_line || test.tags.line}
  end

  defp same_file?(frame_file, file),
    do: Path.expand(to_string(frame_file)) == Path.expand(file)

  # The earliest {file, line} wins, so a change in ExUnit's module order fails a golden test
  # instead of naming a later koan.
  @spec earliest([map()]) :: map() | nil
  def earliest([]), do: nil

  def earliest(failures) do
    failures |> Enum.min_by(& &1.sort_key) |> Map.delete(:sort_key)
  end

  @spec blank(term()) :: Exception.t() | nil
  def blank(reason), do: find_blank(reason)

  defp find_blank(%Koans.Blank{} = blank), do: blank
  defp find_blank(tuple) when is_tuple(tuple), do: tuple |> Tuple.to_list() |> find_blank()
  defp find_blank([head | tail]), do: find_blank(head) || find_blank_tail(tail)
  defp find_blank(_), do: nil

  defp find_blank_tail(tail) when is_list(tail), do: find_blank(tail)
  defp find_blank_tail(_), do: nil

  defp separator(title) do
    padded = " #{title} "
    fill = @width - String.length(padded)
    left = div(fill, 2)
    String.duplicate("-", left) <> padded <> String.duplicate("-", fill - left)
  end
end
