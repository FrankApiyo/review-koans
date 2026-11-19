defmodule Invoice do
  def total(lines) do
    Enum.reduce(lines, 0, fn %{qty: qty, unit: unit}, acc -> acc + qty * unit end)
  end
end

defmodule Ending do
  def reject, do: raise(ArgumentError, "qty must be an integer")
  def shut_down, do: exit(:shutdown)
  def give_up, do: throw(:oops)
end

# The logger can print a report after the script has exited. This handler prints each report
# as the default handler would, then tells the script, so every run prints the same output.
defmodule Printed do
  def log(event, %{formatter: {formatter, options}, config: %{script: script}}) do
    IO.write(formatter.format(event, options))
    send(script, :printed)
  end

  def run(module, function, args, reports) do
    {pid, ref} = spawn_monitor(module, function, args)

    receive do
      {:DOWN, ^ref, :process, ^pid, _reason} -> :ok
    end

    for _ <- 1..reports//1 do
      receive do
        :printed -> :ok
      end
    end
  end
end

{:ok, default} = :logger.get_handler_config(:default)
:ok = :logger.remove_handler(:default)

:ok =
  :logger.add_handler(:printed, Printed, %{
    formatter: default.formatter,
    config: %{script: self()}
  })

lines = [%{qty: 2, unit: 500}, %{qty: "3", unit: 250}]
Printed.run(Invoice, :total, [lines], 1)
Printed.run(Ending, :reject, [], 1)
Printed.run(Ending, :shut_down, [], 0)
Printed.run(Ending, :give_up, [], 1)
