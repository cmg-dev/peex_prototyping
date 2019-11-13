
defmodule Peex.Core.ExclusiveJoinGateway do
  use Peex.Core.FlowNode

  require Logger

  def handle_cast({:on_enter, token}, state) do

    _persist_on_enter(token, state, "")

    next_node_id = state.next_node_id

    { :ok, token } = _persist_on_exit(token, state, token.payload)

    Logger.debug "#{__MODULE__} Starting next -> #{next_node_id}"
    Logger.debug "#{__MODULE__} token: #{inspect(token)}"

    try_cast(next_node_id, {:on_enter, token})

    {:noreply, state}
  end
end
