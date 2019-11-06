defmodule MkIScriptTask do
  use GenServer

  # ----------------------------------------- #
  # Client - API                              #
  # i.e. Client calls the following functions #
  # ----------------------------------------- #
  def start_link([next_node_name, config], flow_node_id) do
    GenServer.start_link(
      __MODULE__,
      [next_node_name, config],
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
    [next_node_name, config] = state
    [meta_instance_id, _] = token 

    IO.puts 'Script Task reached'
    # {{{ do some work
    # eval(...)
    # }}}

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
