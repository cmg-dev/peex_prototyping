
defmodule Peex.Core.EndEvent do
  use Peex.Core.FlowNode

  require Logger

  # ----------------------------------------- #
  # Server - API                              #
  # i.e. Server calls the following functions #
  # ----------------------------------------- #

  def handle_cast({:on_enter, token}, state) do

    Logger.debug "#{__MODULE__} End event reached"
    Logger.debug "#{__MODULE__} token: #{inspect(token)}"

    {:noreply, state}
  end
end
