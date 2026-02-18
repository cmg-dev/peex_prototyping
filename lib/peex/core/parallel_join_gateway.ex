defmodule Peex.Core.ParallelJoinGateway do
  use Peex.Core.FlowNode

  require Logger

  def handle_cast({:on_enter, token}, state) do
    next_node_id = state.next_node_id
    _try_cast(next_node_id, {:on_enter, token})
    {:noreply, state}
  end
end
