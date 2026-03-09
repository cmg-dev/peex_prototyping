defmodule Peex.Core.InclusiveJoinGateway do
  use Peex.Core.FlowNode

  require Logger

  @impl true
  def init(config) do
    {:ok, Map.put(config, :join_state, %{})}
  end

  # A token has arrived at the join from one of the incoming paths.
  @impl true
  def handle_cast({:on_enter, token}, state) do
    pid = token.process_instance_id
    marker = Enum.find(token.markers || [], &(&1.join_id == state.id))

    inst = Map.get(state.join_state, pid, %{expected: nil, arrived: [], not_coming_count: 0})
    expected = inst.expected || (marker && marker.expected)
    arrived = inst.arrived ++ [token]
    inst = %{inst | expected: expected, arrived: arrived}

    Logger.debug("#{__MODULE__} Token arrived (instance=#{pid}, arrived=#{length(arrived)}, not_coming=#{inst.not_coming_count}, expected=#{inspect(expected)})")

    state = put_in(state, [:join_state, pid], inst)
    _maybe_activate(state, pid)
  end

  # A token that was expected has been consumed elsewhere (e.g. end event).
  def handle_cast({:token_not_coming, expected, process_instance_id}, state) do
    inst = Map.get(state.join_state, process_instance_id, %{expected: nil, arrived: [], not_coming_count: 0})
    expected = inst.expected || expected
    inst = %{inst | expected: expected, not_coming_count: inst.not_coming_count + 1}

    Logger.debug("#{__MODULE__} Token not coming (instance=#{process_instance_id}, arrived=#{length(inst.arrived)}, not_coming=#{inst.not_coming_count}, expected=#{inspect(expected)})")

    state = put_in(state, [:join_state, process_instance_id], inst)
    _maybe_activate(state, process_instance_id)
  end

  # Check if the join should activate for the given process instance.
  defp _maybe_activate(state, process_instance_id) do
    inst = state.join_state[process_instance_id]
    _maybe_activate_for_instance(inst, state, process_instance_id)
  end

  defp _maybe_activate_for_instance(%{expected: nil} = _inst, state, _process_instance_id) do
    {:noreply, state}
  end

  defp _maybe_activate_for_instance(%{arrived: arrived, not_coming_count: not_coming_count, expected: expected} = inst, state, process_instance_id)
       when length(arrived) + not_coming_count >= expected do
    _activate(state, process_instance_id, inst)
  end

  defp _maybe_activate_for_instance(_inst, state, _process_instance_id) do
    {:noreply, state}
  end

  # All expected tokens accounted for — merge payloads and continue.
  defp _activate(state, process_instance_id, inst) do
    Logger.debug("#{__MODULE__} Activating join (instance=#{process_instance_id}, arrived=#{length(inst.arrived)})")

    merged_payload =
      Enum.reduce(inst.arrived, %{}, fn t, acc -> Map.merge(acc, t.payload) end)

    survivor = List.first(inst.arrived)
    markers = Enum.reject(survivor.markers || [], &(&1.join_id == state.id))
    survivor = %{survivor | markers: markers}

    _persist_on_enter(survivor, state, "")
    {:ok, survivor} = _persist_on_exit(survivor, state, merged_payload)

    Logger.debug("#{__MODULE__} Starting next -> #{state.next_node_id}")

    _try_cast(state.next_node_id, {:on_enter, survivor})

    state = update_in(state, [:join_state], &Map.delete(&1, process_instance_id))
    {:noreply, state}
  end
end
