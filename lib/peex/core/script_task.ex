
defmodule Peex.Core.ScriptTask do
  use Peex.Core.FlowNode

  require Logger

  def handle_cast({:on_enter, token}, state) do

    _persist_on_enter(token, state, "")

    next_node_id = state.next_node_id

    script = state.script
    evaluation_data = [token: token]

    {updated_payload, _} = Code.eval_string(script, evaluation_data)

    # new_token = Map.put(token, :payload, new_payload)

    { :ok, token } = _persist_on_exit(token, state, updated_payload)

    Logger.debug "#{__MODULE__} Starting next -> #{next_node_id}"
    Logger.debug "#{__MODULE__} token: #{inspect(token)}"

    _try_cast(next_node_id, {:on_enter, token})

    {:noreply, state}
  end
end
