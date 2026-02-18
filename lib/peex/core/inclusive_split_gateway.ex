defmodule Peex.Core.InclusiveSplitGateway do
  use Peex.Core.FlowNode

  require Logger

  def handle_cast({:on_enter, token}, state) do
    _persist_on_enter(token, state, "")

    evaluation_data = [token: token]
    activated_nodes = _get_activated_nodes(state.next_nodes, evaluation_data)
    expected = length(activated_nodes)

    Logger.debug("#{__MODULE__} Activated #{expected} paths for join #{state.paired_join_id}")

    markers = (token.markers || []) ++ [%{join_id: state.paired_join_id, expected: expected}]
    token = %{token | markers: markers}

    {:ok, token} = _persist_on_exit(token, state, token.payload)

    Enum.each(activated_nodes, fn node ->
      Logger.debug("#{__MODULE__} Forking to -> #{node.id}")
      _try_cast(node.id, {:on_enter, token})
    end)

    {:noreply, state}
  end

  # Inclusive split: take ALL paths where condition is true or condition is nil (unconditional).
  defp _get_activated_nodes(nodes, data) do
    activated =
      Enum.filter(nodes, fn node ->
        case node.condition do
          nil ->
            true

          condition ->
            case Code.eval_string(condition, data) do
              {true, _} -> true
              _ -> false
            end
        end
      end)

    if Enum.empty?(activated) do
      Logger.error("#{__MODULE__} No path activated — at least one is required by BPMN spec")
      []
    else
      activated
    end
  end
end
