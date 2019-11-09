
defmodule Peex.Core.ExclusiveSplitGateway do
  use Peex.Core.FlowNode

  require Logger

  # ----------------------------------------- #
  # Server - API                              #
  # i.e. Server calls the following functions #
  # ----------------------------------------- #

  def handle_cast({:on_enter, token}, state) do

    next_nodes = state.next_nodes

    evaluation_data = [token: token]

    next_node = next_nodes |> Enum.find(fn next_node ->

      case Code.eval_string(next_node.condition, evaluation_data) do
       { true, _ } -> true
       _ -> false
      end
    end)

    if next_node do

      next_node_id = next_node.id

      Logger.debug "#{__MODULE__} Starting next -> #{next_node_id}"
      Logger.debug "#{__MODULE__} token: #{inspect(token)}"

      try_cast(next_node_id, {:on_enter, token})

    else
      Logger.debug "#{__MODULE__} No matching branch found"
    end

    {:noreply, state}
  end
end
