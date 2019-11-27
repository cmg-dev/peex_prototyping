defmodule Peex.Persistence.Application do
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    children = [
      Peex.Persistence.Repo,
    ]

    opts = [strategy: :one_for_one, name: Peex.Persistence.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
