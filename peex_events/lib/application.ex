defmodule Peex.Events.Application do
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    children = [
        Peex.Events.Repo,
    ]

    Logger.debug 'stared called'

    opts = [strategy: :one_for_one, name: Peex.Events.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
