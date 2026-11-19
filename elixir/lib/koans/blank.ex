defmodule Koans.Blank do
  defexception [:message, :file, :line]

  @value_message "Replace __ with the value that makes this true."
  @code_message "Replace __() with the code the meditation describes."

  @spec value!(String.t(), pos_integer()) :: no_return()
  def value!(file, line),
    do: opaque_raise(%__MODULE__{message: @value_message, file: file, line: line})

  @spec code!(String.t(), pos_integer()) :: no_return()
  def code!(file, line),
    do: opaque_raise(%__MODULE__{message: @code_message, file: file, line: line})

  @spec verdict!(String.t(), pos_integer(), String.t()) :: no_return()
  def verdict!(file, line, review_path) do
    message = "Replace __ with :fine, or the number of the line with the bug in #{review_path}."
    opaque_raise(%__MODULE__{message: message, file: file, line: line})
  end

  # apply/3 keeps the type checker from flagging expressions that always raise.
  defp opaque_raise(exception), do: apply(:erlang, :error, [exception])
end
