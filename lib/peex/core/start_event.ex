
defmodule Peex.Core.StartEvent do
  use Peex.Core.FlowNode

  require Logger

  # ----------------------------------------- #
  # Client - API                              #
  # i.e. Client calls the following functions #
  # ----------------------------------------- #

  def start(start_node_id, token) do
    try_cast(start_node_id, {:on_enter, token})
  end

  # ----------------------------------------- #
  # Server - API                              #
  # i.e. Server calls the following functions #
  # ----------------------------------------- #

  def handle_cast({:on_enter, token}, state) do

    next_node_id = state.next_node_id

    Logger.debug "#{__MODULE__} Starting next -> #{next_node_id}"
    Logger.debug "#{__MODULE__} token: #{inspect(token)}"

    try_cast(next_node_id, {:on_enter, token})

    {:noreply, state}
  end
end
