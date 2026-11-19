defmodule Report do
  def build(rows) do
    task = Task.async(__MODULE__, :upcase_all, [rows])
    {:ok, Task.await(task)}
  end

  def upcase_all(rows), do: Enum.map(rows, &String.upcase/1)
end

# The logger can print a report after the script has exited. This handler prints each report
# as the default handler would, then tells the script, so every run prints the same output.
defmodule Printed do
  def log(event, %{formatter: {formatter, options}, config: %{script: script}}) do
    IO.write(formatter.format(event, options))
    send(script, :printed)
  end
end

{:ok, default} = :logger.get_handler_config(:default)
:ok = :logger.remove_handler(:default)

:ok =
  :logger.add_handler(:printed, Printed, %{
    formatter: default.formatter,
    config: %{script: self()}
  })

{caller, ref} = spawn_monitor(Report, :build, [["a", :b]])

receive do
  {:DOWN, ^ref, :process, ^caller, _reason} -> :ok
end

receive do
  :printed -> :ok
end
