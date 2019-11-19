
defmodule Peex.Core.ServiceTask do
  use Peex.Core.FlowNode

  require Logger

  def handle_cast({:on_enter, token}, state) do

    _persist_on_enter(token, state, "")

    next_node_id = state.next_node_id
    topic = state.topic

    namespaces =  _get_namespaces_from_topic(topic)

    module = _get_module_name_from_namespaces(namespaces) 

    prefixed_module = "Elixir.#{module}" |> String.to_atom()

    service_function = _build_service_function(namespaces)

    updated_payload = apply(prefixed_module, service_function, [token])

    { :ok, token } = _persist_on_exit(token, state, updated_payload)

    Logger.debug "#{__MODULE__} Starting next -> #{next_node_id}"
    Logger.debug "#{__MODULE__} token: #{inspect(token)}"

    _try_cast(next_node_id, {:on_enter, token})

    {:noreply, state}
  end

  defp _get_namespaces_from_topic(topic) do
    topic |> to_string() |> String.split(".")
  end

  defp _get_module_name_from_namespaces(namespaces) do
    namespaces |> Enum.drop(-1) |> Enum.join(".")
  end

  defp _build_service_function(namespaces) do
    namespaces |> Enum.to_list() |> List.last() |> String.to_atom
  end

end
