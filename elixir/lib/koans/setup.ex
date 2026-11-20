defmodule Koans.Setup do
  alias Support.Db

  @endpoint_config [
    secret_key_base: String.duplicate("review-koans-", 5) |> binary_part(0, 64),
    live_view: [signing_salt: "review-koans"],
    pubsub_server: Support.PubSub,
    render_errors: [formats: [html: Support.ErrorHTML], layout: false],
    server: false
  ]

  # A crash report that lands after its koan ends would print a check's input;
  # with capture_log on, no other log reaches the default handler.
  @spec start!() :: :ok
  def start! do
    _ = :logger.remove_handler(:default)
    put_env()
    Enum.each(Db.files(), &File.rm/1)

    {:ok, _} =
      Supervisor.start_link(
        [Support.Repo, {Phoenix.PubSub, name: Support.PubSub}, Support.Endpoint],
        strategy: :one_for_one,
        name: Support.Supervisor
      )

    Support.Migrations.run!()
  end

  defp put_env do
    Application.put_env(:phoenix, :json_library, Jason)

    Application.put_env(:review_koans, Support.Repo,
      database: Db.path(),
      pool_size: 1,
      log: false,
      telemetry_prefix: [:review_koans, :repo]
    )

    Application.put_env(:review_koans, Support.Endpoint, @endpoint_config)
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
