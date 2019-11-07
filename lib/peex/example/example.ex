
defmodule Peex.Example do

  require Logger

  def start do

    Logger.debug "Starting Example Process"

    {:ok, _} = Peex.Example.ProcessSupervisor.start_link([])

    token = %{instance_id: 100, payload: nil}

    Peex.Core.StartEvent.start(:StartEvent_1, token)
  end
end
