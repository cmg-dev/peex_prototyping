
defmodule Peex.Core.FlowNode do

  defmacro __using__(_options) do
    quote do

      use GenServer

      def start_link(state, flow_node_id) do
        GenServer.start_link(
          __MODULE__,
          state,
          name: global_server_name(flow_node_id))
      end

      @impl true
      def init(state) do
        {:ok, state}
      end

      defp global_server_name(server_name) do
        {:global, {:servername, server_name}}
      end

      defp try_cast(server_name, message) do
        case GenServer.whereis(global_server_name(server_name)) do
          nil ->
            {:error, :invalid_server}

          servername ->
            GenServer.cast(servername, message)
        end
      end
    end
  end
end
