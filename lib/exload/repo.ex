defmodule Exload.Repo do
  use Ecto.Repo,
    otp_app: :Exload,
    adapter: Ecto.Adapters.Postgres
end
