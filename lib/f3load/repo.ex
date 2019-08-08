defmodule F3load.Repo do
  use Ecto.Repo,
    otp_app: :f3load,
    adapter: Ecto.Adapters.Postgres
end
