defmodule MkIEndEvent do
  use GenServer

  require Logger
  # ----------------------------------------- #
  # Client - API                              #
  # i.e. Client calls the following functions #
  # ----------------------------------------- #

  def start_link(state, flow_node_id) do
    GenServer.start_link(
      __MODULE__,
      state,
      name: global_server_name(flow_node_id))
    end

  # ----------------------------------------- #
  # Server - API                              #
  # i.e. Server calls the following functions #
  # ----------------------------------------- #
  def handle_cast({:on_enter, token}, state) do
    Logger.debug "End Event reached"

    # TODO: This could be a nice idea to retrieve the
    #       token at the end of the process 
    # GenServer.cast(finish_message_recipient, {:finished, token})
    {:noreply, state}

  end

  defp global_server_name(server_name) do
    {:global, {:servername, server_name}}
  end

  defp try_call(server_name, message) do
    case GenServer.whereis(global_server_name(server_name)) do
      nil ->
        {:error, :invalid_server}

      servername ->
        GenServer.cast(servername, message)
    end
  end
end
