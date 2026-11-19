defmodule Course.Ch02.Report do
  @moduledoc "Upper-cases each row in a Task and waits for the result."

  @spec build([String.t()]) :: {:ok, [String.t()]}
  def build(rows) do
    task = Task.async(__MODULE__, :upcase_all, [rows])
    {:ok, Task.await(task)}
  end

  @spec upcase_all([String.t()]) :: [String.t()]
  def upcase_all(rows), do: Enum.map(rows, &String.upcase/1)
end
