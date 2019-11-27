
defmodule Peex.Core.StartEvent do
  use Peex.Core.FlowNode

  require Logger

  def start(start_node_id, token) do
    _try_cast(start_node_id, {:on_enter, token})
  end

  def handle_cast({:on_enter, token}, state) do
    token = _persist_on_start(token, state, "")

    next_node_id = state.next_node_id

    Logger.debug "#{__MODULE__} Starting next -> #{next_node_id}"
    Logger.debug "#{__MODULE__} token: #{inspect(token)}"

    _try_cast(next_node_id, {:on_enter, token})

    _persist_on_exit(token, state)

    {:noreply, state}
  end

  defp _persist_on_start(token, state, "") do
    token
    |> Map.put(:payload, token.payload)
    |> Map.put(:flow_node_instance_id, state.instance_id)
    |> Map.put(:flow_node_id, to_string(state.id))
    |> Map.put(:parent_caller_instance_id, nil)
    |> Repo.insert!
  end
end
