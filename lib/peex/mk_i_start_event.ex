defmodule MkIStartEvent do
  use GenServer

  require Logger
  # ----------------------------------------- #
  # Client - API                              #
  # i.e. Client calls the following functions #
  # ----------------------------------------- #

  def start_link(next_node_name, flow_node_id) do
    GenServer.start_link(
      __MODULE__,
      next_node_name,
      name: global_server_name(flow_node_id))
  end

  def init(state) do
    {:ok, state}
  end

  def start(start_event_name, token) do
    try_call(start_event_name, {:on_enter, token})
  end

  # ----------------------------------------- #
  # Server - API                              #
  # i.e. Server calls the following functions #
  # ----------------------------------------- #
  def handle_cast({:on_enter, token}, state) do
    Logger.debug "Start Event reached"

    [next_node_name] = state

    Logger.debug "#{__MODULE__} Starting next -> #{next_node_name}"

    try_call(next_node_name, {:on_enter, token})

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
