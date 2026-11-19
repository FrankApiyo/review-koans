defmodule Koans.Verdict do
  defexception [:message]

  @spec check!(String.t(), term(), String.t(), String.t()) :: :ok
  def check!(file, answer, digests, source_digest) do
    path = review_path(file)
    accepted = String.split(digests, ",")
    fine? = digest(file, :fine) in accepted

    case judge(file, answer, accepted, fine?) do
      :ok -> :ok
      :bad_shape -> refuse("Write :fine, or a line number of #{path} as an integer.")
      :is_fine -> refuse("Read #{path} again: it is fine. Write :fine.")
      :has_bug -> refuse("Not fine: #{path} has a bug. Write the number of the line where it is.")
      :wrong_line -> refuse(wrong_line(path, source_digest))
    end
  end

  @spec digest(String.t(), integer() | :fine) :: String.t()
  def digest(file, answer) do
    :sha256
    |> :crypto.hash("#{file}:#{answer}")
    |> short()
  end

  @spec review_path(String.t()) :: String.t()
  def review_path(file), do: Path.join([System.get_env("KOANS_DIR", "koans"), "review", file])

  defp judge(_file, answer, _accepted, _fine?)
       when answer != :fine and not (is_integer(answer) and answer > 0),
       do: :bad_shape

  defp judge(_file, :fine, _accepted, true), do: :ok
  defp judge(_file, _line, _accepted, true), do: :is_fine
  defp judge(_file, :fine, _accepted, false), do: :has_bug

  defp judge(file, line, accepted, false) do
    if digest(file, line) in accepted, do: :ok, else: :wrong_line
  end

  defp wrong_line(path, source_digest) do
    message = "Not that line. Look again at #{path}."

    if changed?(path, source_digest) do
      message <>
        "\n#{path} has changed since it was generated, so its line numbers may have moved: " <>
        "git diff #{path} shows how."
    else
      message
    end
  end

  defp changed?(path, source_digest) do
    case File.read(path) do
      {:ok, text} -> short(:crypto.hash(:sha256, text)) != source_digest
      {:error, _reason} -> true
    end
  end

  defp short(hash), do: hash |> Base.encode16(case: :lower) |> binary_part(0, 10)

  defp refuse(message), do: raise(%__MODULE__{message: message})
end
