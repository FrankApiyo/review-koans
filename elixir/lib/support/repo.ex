defmodule Support.Repo do
  use Ecto.Repo, otp_app: :review_koans, adapter: Ecto.Adapters.SQLite3
end
