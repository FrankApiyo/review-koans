defmodule Koans.Trace do
  @moduledoc """
  Answers read from a captured fixture, `traces/<name>.exs.trace` relative to the working
  directory.

  An answer never holds a pid, ref, port or LiveView id, since those change on every capture:
  an extractor that would return one raises instead, and the trace program has to change.
  """

  @exception ~r/\*\* \((?!EXIT\))([A-Z]\w*(?:\.[A-Z]\w*)*)\)/
  @frame ~r/^\s+(traces\/[^\s:]+):(\d+):/m
  @report ~r/^\[error\] /m
  @header ~r/^\[error\] (.*)$/m
  @named_server ~r/^GenServer (.+) terminating$/
  @last_message ~r/^Last message(?: \(from [^)]*\))?: (.*)$/m
  @stop_reason ~r/^\*\* \(stop\) (.*)$/m
  @event ~r/"event" => "([^"]*)"/
  @init_frame ~r/\{\s*([A-Z]\w*(?:\.[A-Z]\w*)*),\s+:init,\s+1,\s+\[\s*file:\s+~c"traces\/[^"]*",\s+line:\s+(\d+)\s*\]\s*\}/
  @varying ~r/#PID<|#Reference<|#Port<|(?<![\w-])phx-(?=[\w-]{0,15}[A-Z0-9])[\w-]{16}(?![\w-])/

  @spec read!(String.t()) :: String.t()
  def read!(name), do: File.read!(Path.join("traces", name <> ".exs.trace"))

  @spec exception(String.t()) :: String.t() | nil
  def exception(name), do: name |> read!() |> first(@exception) |> checked(name)

  @spec first_frame(String.t()) :: {String.t(), pos_integer()} | nil
  def first_frame(name), do: name |> frames() |> List.first()

  @doc "Each course frame once, in the order it first appears."
  @spec frames(String.t()) :: [{String.t(), pos_integer()}]
  def frames(name) do
    @frame
    |> Regex.scan(read!(name), capture: :all_but_first)
    |> Enum.map(fn [file, line] -> {file, String.to_integer(line)} end)
    |> Enum.uniq()
  end

  @spec reports(String.t()) :: non_neg_integer()
  def reports(name), do: @report |> Regex.scan(read!(name)) |> length()

  @spec last_message(String.t()) :: String.t() | nil
  def last_message(name), do: name |> read!() |> first(@last_message) |> checked(name)

  @doc "The first report's `** (stop)` line, as the report words it, without the marker."
  @spec stop_reason(String.t()) :: String.t() | nil
  def stop_reason(name), do: name |> read!() |> first(@stop_reason) |> checked(name)

  @spec process(String.t()) :: String.t() | nil
  def process(name) do
    name |> read!() |> first(@header) |> process_in() |> checked(name)
  end

  @spec event(String.t()) :: String.t() | nil
  def event(name) do
    @last_message
    |> Regex.scan(read!(name), capture: :all_but_first)
    |> Enum.find_value(fn [message] -> first(message, @event) end)
    |> checked(name)
  end

  @doc "The module and line of the first course `init/1` frame in a start error's stacktrace term."
  @spec init_failure(String.t()) :: {String.t(), pos_integer()} | nil
  def init_failure(name) do
    case Regex.run(@init_frame, read!(name), capture: :all_but_first) do
      [module, line] -> {module, String.to_integer(line)}
      nil -> nil
    end
  end

  defp first(text, regex) do
    case Regex.run(regex, text, capture: :all_but_first) do
      [match] -> match
      nil -> nil
    end
  end

  defp process_in("GenServer #PID<" <> _), do: "GenServer"
  defp process_in("GenServer " <> _ = header), do: first(header, @named_server)
  defp process_in("Task " <> _), do: "Task"
  defp process_in("Process " <> _), do: "Process"
  defp process_in(_header), do: nil

  defp checked(answer, name) when is_binary(answer) do
    if Regex.match?(@varying, answer) do
      raise ArgumentError,
            "traces/#{name}.exs.trace: the answer #{inspect(answer)} holds a pid, ref, port " <>
              "or LiveView id, which changes on every capture; change the trace program"
    end

    answer
  end

  defp checked(nil, _name), do: nil
end
