defmodule MkIExclusiveSplitGateway do
  use GenServer

  require Integer
  # ----------------------------------------- #
  # Client - API                              #
  # i.e. Client calls the following functions #
  # ----------------------------------------- #

  # nodes_and_expressions = %{:nodeA: expression, :nodeB: expression }

  def start_link(nodes, flow_node_id) do

    condition = 0

    state = [nodes, condition]

    GenServer.start_link(
      __MODULE__,
      state,
      name: global_server_name(flow_node_id))
  end

  def init(state) do
    {:ok, state}
  end

  # ----------------------------------------- #
  # Server - API                              #
  # i.e. Server calls the following functions #
  # ----------------------------------------- #
  def handle_cast({:on_enter, token}, state) do
    [[evenNode, oddNode], condition] = state

    IO.puts "Split Gateway reached"
    # {{{ do some work
    # implement real condition check
    case Integer.is_even(condition) do
      :true ->
        try_call(evenNode, {:on_enter, token})
      :false ->
        try_call(oddNode, {:on_enter, token})
    end
    # }}}

    {:noreply, [[evenNode, oddNode], condition + 1]}
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
