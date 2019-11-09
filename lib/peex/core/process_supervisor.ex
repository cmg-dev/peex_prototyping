

defmodule Peex.Core.ProcessSupervisor do
  use Supervisor

  require Logger

  def start_link(state) do
    Supervisor.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(nodes_with_config) do

    IO.inspect(nodes_with_config)

    children = nodes_with_config |> Enum.map(fn {node, config} ->

      id = to_string(config.id) |> String.to_atom()

      new_config = case config do
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

      child = %{
        id: id,
        start: {node, :start_link, [new_config, id]}
      }

      child
    end)

    Supervisor.init(children, strategy: :one_for_one)
  end

end
