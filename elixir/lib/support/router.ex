defmodule Support.Router do
  use Phoenix.Router

  import Phoenix.LiveView.Router

  # Review modules compile with the koans and solutions trees; the verify build has none.
  @compile {:no_warn_undefined, Review.Ch07.NotesLive}

  pipeline :browser do
    plug :fetch_query_params
    plug :fetch_session
  end

  scope "/ch07" do
    pipe_through :browser

    live "/dashboard", Course.Ch07.DashboardLive
    live "/notes", Review.Ch07.NotesLive
  end
end
