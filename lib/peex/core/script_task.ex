
defmodule Peex.Core.ScriptTask do
  use Peex.Core.FlowNode

  require Logger

  # ----------------------------------------- #
  # Server - API                              #
  # i.e. Server calls the following functions #
  # ----------------------------------------- #

  def handle_cast({:on_enter, token}, state) do

    next_node_id = state.next_node_id
    script = state.script

    evaluation_data = [token: token]

    {new_payload, _} = Code.eval_string(script, evaluation_data)

    new_token = Map.put(token, :payload, new_payload)

    Logger.debug "#{__MODULE__} Starting next -> #{next_node_id}"
    Logger.debug "#{__MODULE__} token: #{inspect(new_token)}"

    try_cast(next_node_id, {:on_enter, new_token})

    {:noreply, state}
  end
end
