defmodule Interface.Repo do
  use Ecto.Repo,
    otp_app: :interface,
    adapter: Ecto.Adapters.Postgres
end
