
defmodule Peex.Core.ExclusiveSplitGateway do
  use Peex.Core.FlowNode

  require Logger

  def handle_cast({:on_enter, token}, state) do

    _persist_on_enter(token, state, "")

    next_nodes = state.next_nodes

    evaluation_data = [token: token]

    next_node = _get_next_node(next_nodes, evaluation_data) 

    next_node_id = next_node.id

    if next_node_id do

      Logger.debug "#{__MODULE__} Starting next -> #{next_node_id}"
      Logger.debug "#{__MODULE__} token: #{inspect(token)}"

      { :ok, token } = _persist_on_exit(token, state, token.payload)

      try_cast(next_node_id, {:on_enter, token})

    else
      Logger.error "#{__MODULE__} No matching branch found"
    end

    {:noreply, state}
  end

  defp _get_next_node(nodes, data) do
    nodes
    |> Enum.find(fn node ->
        case Code.eval_string(node.condition, data) do
          # a successful match to the condition, will result in true
          { true, _ } -> true
          # the default route will match to nil, as it has no condition
          { nil, _ } -> true 
          # this should not happen TODO: take care about this later
          _ -> false
        end
      end)
  end
end
