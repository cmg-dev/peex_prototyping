defmodule MkIServiceTask do
  use GenServer

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

  def init(init_arg) do
    {:ok, init_arg}
  end

  # ----------------------------------------- #
  # Server - API                              #
  # i.e. Server calls the following functions #
  # ----------------------------------------- #
  def handle_cast({:on_enter, token}, state) do

    IO.puts "Service Task reached"

    [next_node_name] = state
    [meta_instance_id] = token

    IO.puts "my id is: #{meta_instance_id}"

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
