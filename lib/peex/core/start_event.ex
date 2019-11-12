
defmodule Peex.Core.StartEvent do
  use Peex.Core.FlowNode

  require Logger

  def start(start_node_id, token) do
    try_cast(start_node_id, {:on_enter, token})
  end

  def handle_cast({:on_enter, token}, state) do
    token = persist_on_start(token, state, "")

    Logger.debug "#{__MODULE__} Using token -> #{inspect(token)}"

    next_node_id = state.next_node_id

    Logger.debug "#{__MODULE__} Starting next -> #{next_node_id}"
    Logger.debug "#{__MODULE__} token: #{inspect(token)}"

    try_cast(next_node_id, {:on_enter, token})

    _persist_on_exit(token, state)

    {:noreply, state}
  end

  defp persist_on_start(token, state, "") do
    token = %{ token | payload: token.payload,
      flow_node_instance_id: state.instance_id,
      parent_caller_instance_id: nil
    }

    Logger.debug "persist_on_start #{inspect(token)}"

    Repo.insert!(token)
  end
end
