
defmodule Peex.Core.FlowNode do

  defmacro __using__(_options) do
    quote do

      use GenServer

      alias Peex.Persistence.Repo, as: Repo
      alias Peex.Contracts.Processtoken, as: Token

      require Logger

      def start_link(state, flow_node_id) do
        GenServer.start_link(
          __MODULE__,
          state,
          name: _global_server_name(flow_node_id))
      end

      @impl true
      def init(state) do
        {:ok, state}
      end

      defp _global_server_name(server_name) do
        {:global, {:servername, server_name}}
      end

      defp _try_cast(server_name, message) do
        case GenServer.whereis(_global_server_name(server_name)) do
          nil ->
            {:error, :invalid_server}

          servername ->
            GenServer.cast(servername, message)
        end
      end

      defp _persist_on_enter(token, state, caller) do
        Logger.debug "#{__MODULE__} Persisting token 'on enter' in #{state.id} token #{inspect(token)}"
        Logger.debug "#{__MODULE__} Persisting token 'on enter' in #{state.id} token #{inspect(token)}"

        {:ok, updated_token} = token
        |> Token.changeset(
          %{
            "flow_node_instance_id" => state.instance_id,
            "flow_node_id" => to_string(state.id),
            "parent_caller_instance_id" => nil
          })
        |> Repo.update

        active_flow_node_message = %{
          "flow_node_id" => updated_token.flow_node_id
        }

        Peex.Events.Repo.publish(active_flow_node_message)

        {:ok, updated_token}
      end

      defp _persist_on_exit(token, state, payload \\ %{}) do
        Logger.debug "#{__MODULE__} Persisting token 'on exit' in #{state.id}"

        token
        |> Token.changeset(
          %{
            "payload" => payload,
          })
        |> Repo.update
      end
    end
  end
end
