defmodule Peex.API.Application do
  use Application

  require Logger

  def start(_type, _args) do

    children = [
      {Plug.Cowboy, scheme: :http, plug: Peex.API.Router, options: [port: 4000]}
    ]

    Logger.info("Starting application...")

    Supervisor.start_link(children, [strategy: :one_for_one, name: Peex.API.Application])
  end

end
