defmodule Peex.Persistence.Repo do
  use Ecto.Repo,
    otp_app: :peex_persistence,
    adapter: Ecto.Adapters.Postgres
end
