
defmodule Peex.Core.ServiceTask do
  use Peex.Core.FlowNode

  require Logger

  # ----------------------------------------- #
  # Server - API                              #
  # i.e. Server calls the following functions #
  # ----------------------------------------- #

  def handle_cast({:on_enter, token}, state) do

    next_node_id = state.next_node_id
    %{:instance_id => instance_id, :payload => payload} = token

    updated_counter = payload.counter + 1
    updated_payload = %{counter: updated_counter}

    new_token = Map.put(token, :payload, updated_payload)

    Logger.debug "#{__MODULE__} Starting next -> #{next_node_id}"
    Logger.debug "#{__MODULE__} token: #{inspect(new_token)}"

    try_cast(next_node_id, {:on_enter, new_token})

    {:noreply, state}
  end
end
