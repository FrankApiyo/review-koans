defmodule Koans.Setup do
  # A crash report that lands after its koan ends would print a check's input;
  # with capture_log on, no other log reaches the default handler.
  @spec start!() :: :ok
  def start! do
    _ = :logger.remove_handler(:default)
    :ok
  end

  @spec ex_unit_options() :: keyword()
  def ex_unit_options do
    base = [
      seed: 0,
      timeout: 5_000,
      capture_log: true,
      max_cases: 1,
      formatters: [Koans.Formatter]
    ]

    if verify?(), do: base, else: base ++ [max_failures: 1]
  end

  @spec verify?() :: boolean()
  def verify?, do: System.get_env("KOANS_VERIFY") == "1"
end
