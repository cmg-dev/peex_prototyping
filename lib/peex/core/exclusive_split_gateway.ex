
defmodule Peex.Core.ExclusiveSplitGateway do
  use Peex.Core.FlowNode

  require Logger

  # ----------------------------------------- #
  # Server - API                              #
  # i.e. Server calls the following functions #
  # ----------------------------------------- #

  def handle_cast({:on_enter, token}, state) do

    branches = state.branches

    evaluation_data = [token: token]

    branch = Enum.find(branches, fn branch ->

      case Code.eval_string(branch.condition, evaluation_data) do
       { true, _ } -> true
       _ -> false
      end
    end)

    if branch do

      next_node_id = branch.next_node_id

      Logger.debug "#{__MODULE__} Starting next -> #{next_node_id}"
      Logger.debug "#{__MODULE__} token: #{inspect(token)}"

      try_cast(next_node_id, {:on_enter, token})

    else
      Logger.debug "#{__MODULE__} No matching branch found"
    end

    {:noreply, state}
  end
end
