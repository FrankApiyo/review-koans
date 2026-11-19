defmodule Koans.Hidden do
  alias Koans.HiddenCase

  @spec run_checks(module(), module()) :: :ok
  def run_checks(checks, review) do
    run_cases(checks.cases(), review)
    :ok
  end

  @spec review_path(module()) :: String.t()
  def review_path(review) do
    review.module_info(:compile)[:source]
    |> to_string()
    |> Path.relative_to_cwd()
  end

  @spec isolated((-> any()), pos_integer()) :: {:ok, any()} | {:down, term()} | :timeout
  def isolated(fun, timeout_ms \\ 1_000) do
    {pid, ref} = spawn_monitor(fn -> exit({__MODULE__, :returned, fun.()}) end)

    receive do
      {:DOWN, ^ref, :process, ^pid, reason} -> outcome(reason)
    after
      timeout_ms ->
        Process.exit(pid, :kill)

        receive do
          {:DOWN, ^ref, :process, ^pid, :killed} -> :timeout
          {:DOWN, ^ref, :process, ^pid, reason} -> outcome(reason)
        end
    end
  end

  @spec wait_until((-> boolean()), pos_integer()) :: boolean()
  def wait_until(condition, tries \\ 100_000)

  def wait_until(condition, tries) when is_integer(tries) and tries > 0 do
    cond do
      condition.() ->
        true

      tries == 1 ->
        false

      true ->
        :erlang.yield()
        wait_until(condition, tries - 1)
    end
  end

  defp outcome({__MODULE__, :returned, value}), do: {:ok, value}
  defp outcome(reason), do: {:down, reason}

  defp run_cases([], _review), do: :ok

  defp run_cases([{kind, label, fun} | rest], review) do
    case run_case(fun) do
      :passed ->
        run_cases(rest, review)

      {:failed, cause} ->
        raise %HiddenCase{
          label: label,
          kind: kind,
          review_path: review_path(review),
          cause: cause
        }
    end
  end

  # Only the cause's module survives, so no input value or diff reaches the learner.
  defp run_case(fun) do
    fun.()
    :passed
  rescue
    ExUnit.AssertionError -> {:failed, nil}
    error -> {:failed, {:raised, error.__struct__}}
  catch
    kind, _reason when kind in [:exit, :throw] -> {:failed, :exited}
  end
end
