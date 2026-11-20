# needs: deps
defmodule Checkout do
  use Phoenix.LiveView

  def mount(_params, _session, socket), do: {:ok, assign(socket, cart: %{items: []})}

  def handle_event("checkout", _params, socket) do
    total = socket.assigns.cart.total
    {:noreply, assign(socket, total: total)}
  end

  def render(assigns), do: ~H|<button phx-click="checkout">pay</button>|
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
:ok = Koans.Setup.start!()

:ok =
  :logger.add_handler(:printed, Printed, %{
    level: :error,
    formatter: default.formatter,
    config: %{script: self()}
  })

# LiveViewTest runs only inside an ExUnit test; with no formatters, ExUnit prints nothing.
ExUnit.start(autorun: false, formatters: [])

defmodule ShopperTest do
  use ExUnit.Case

  import Phoenix.LiveViewTest

  @endpoint Support.Endpoint

  test "a shopper pays" do
    Process.flag(:trap_exit, true)
    {:ok, view, _html} = live_isolated(Phoenix.ConnTest.build_conn(), Checkout)
    catch_exit(view |> element("button") |> render_click())
  end
end

%{failures: 0} = ExUnit.run()

receive do
  :printed -> :ok
end
