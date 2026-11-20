defmodule Support.Endpoint do
  use Phoenix.Endpoint, otp_app: :review_koans

  @session [store: :cookie, key: "_review_koans", signing_salt: "review-koans"]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session]]

  plug Plug.Session, @session
  plug Support.Router
end
