defmodule Peex.Processtoken.Application do
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    children = [
        Peex.Processtoken.Repo,
    ]

    Logger.debug 'stared called'

    opts = [strategy: :one_for_one, name: Peex.Processtoken.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
