
defmodule Peex.Core.FlowNode do

  defmacro __using__(_options) do
    quote do

      use GenServer

      alias Peex.Processtoken.Repo, as: Repo
      alias Contracts.Processtoken, as: Token

      require Logger

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

      defp _persist_on_enter(token, state, caller) do
        Logger.debug "#{__MODULE__} Persisting token 'on enter' in #{state.id} token #{inspect(token)}"

        token = Token.changeset(
          token,
          %{
            "payload" => token.payload,
            ":flow_node_instance_id" => state.instance_id,
            ":parent_caller_instance_id" => nil
          })
        Repo.update(token)
      end

      defp _persist_on_exit(token, state, payload \\ %{}) do
        Logger.debug "#{__MODULE__} Persisting token 'on exit' in #{state.id}"

        token = Token.changeset(token, %{"payload" => payload})
        Repo.update(token)
      end
    end
  end
end
