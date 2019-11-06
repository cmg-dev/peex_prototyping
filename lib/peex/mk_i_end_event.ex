defmodule MkIEndEvent do
  use GenServer

  import Integer
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
    IO.puts 'End Event reached'
    {:noreply, state}
  end

  defp global_server_name(server_name) do
    {:global, {:servername, server_name}}
  end
end
