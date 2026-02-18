defmodule Peex.Core.ParallelSplitGateway do
  use Peex.Core.FlowNode

  require Logger

  def handle_cast({:on_enter, token}, state) do
    next_nodes = state.next_nodes
    Logger.info("TTTTT")

    # evaluation_data = [token: token]
    # next_node = _get_next_node(next_nodes, evaluation_data)
    # next_node_id = next_node.id

    state.next_nodes
    |> Enum.each(fn node ->
      _try_cast(node.id, {:on_enter, token})
    end)

    {:noreply, []}
  end
end
