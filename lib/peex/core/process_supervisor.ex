

defmodule Peex.Core.ProcessSupervisor do
  use Supervisor

  require Logger

  def start_link(state) do
    Supervisor.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(nodes_with_config) do

    Logger.debug "#{inspect(nodes_with_config)}"

    children = nodes_with_config |> Enum.map(fn {node, config} -> _construct_child(node, config) end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  def _construct_child(node, config) do
    id = to_string(config.id) |> String.to_atom()

    # There is always a single node, following the current flow node.
    # But it is possible, that a node has multiple following nodes (e.g. Split Gateway)
    #
    # Flow nodes with single following node have only :next_node_id set in config.
    # Flow nodes with more following nodes have only :next_nodes set in config.
    node_config = case config do
      %{ :next_node_id => next_node_id } ->

        new_next_node_id = next_node_id |> to_string() |> String.to_atom()

        Map.put(config, :next_node_id, new_next_node_id)
      

      %{ :next_nodes => next_nodes } ->

        new_next_nodes = next_nodes |> Enum.map(fn next_node ->
          %{ id: next_node.id |> to_string() |> String.to_atom(), condition: next_node.condition }
        end)

        Map.put(config, :next_nodes, new_next_nodes)

      _ ->
        config
    end

    %{
      id: id,
      start: {node, :start_link, [node_config, id]}
    }

  end


end
