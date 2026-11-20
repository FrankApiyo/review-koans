defmodule Support.Router do
  use Phoenix.Router

  import Phoenix.LiveView.Router

  # verify/support_test.exs defines this LiveView, after lib compiles; it is not course code.
  @compile {:no_warn_undefined, Verify.SupportTest.RoutedLive}

  pipeline :browser do
    plug :fetch_session
  end

  scope "/verify" do
    pipe_through :browser

    live "/routed/:id", Verify.SupportTest.RoutedLive
  end
end
