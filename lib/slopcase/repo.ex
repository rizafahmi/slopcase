defmodule Slopcase.Repo do
  use Ecto.Repo,
    otp_app: :slopcase,
    adapter: Ecto.Adapters.SQLite3
end
