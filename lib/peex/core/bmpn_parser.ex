
defmodule Peex.Core.BPMNParser do
  import SweetXml

  require Logger
  def resolve_target(sequence_node_id, diagram) do

    next_node_id = diagram |> xpath(~x"//bpmn:sequenceFlow[@id = \"#{sequence_node_id}\"]/@targetRef")

    next_node_id
  end

  def parse_script_tasks(diagram) do

    result = diagram |> xmap(
      tasks: [
        ~x"//bpmn:scriptTask"l,
        id: ~x"./@id",
        name: ~x"./@name",
        script: ~x"./bpmn:script/text()",
        next_node_id: ~x"./bpmn:outgoing/text()" |> transform_by(fn node_id -> resolve_target(node_id, diagram) end)
      ]
    )

    script_tasks_with_config = result.tasks |> Enum.map(fn config -> {Peex.Core.ScriptTask, config} end)

    script_tasks_with_config
  end

  def parse_service_tasks(diagram) do

    result = diagram |> xmap(
      tasks: [
        ~x"//bpmn:serviceTask"l,
        id: ~x"./@id",
        name: ~x"./@name",
        topic: ~x"./@camunda:topic",
        next_node_id: ~x"./bpmn:outgoing/text()" |> transform_by(fn node_id -> resolve_target(node_id, diagram) end)
      ]
    )

    service_tasks_with_config = result.tasks |> Enum.map(fn config -> {Peex.Core.ServiceTask, config} end)

    service_tasks_with_config
  end

  def parse_tasks(diagram) do

    result = diagram |> xmap(
      tasks: [
        ~x"//bpmn:task"l,
        id: ~x"./@id",
        name: ~x"./@name",
        next_node_id: ~x"./bpmn:outgoing/text()" |> transform_by(fn node_id -> resolve_target(node_id, diagram) end)
      ]
    )

    result.tasks |> Enum.map(fn config -> {Peex.Core.Task, config} end)
  end

  def parse_start_events(diagram) do

    result = diagram |> xmap(
      tasks: [
        ~x"//bpmn:startEvent"l,
        id: ~x"./@id",
        next_node_id: ~x"./bpmn:outgoing/text()" |> transform_by(fn node_id -> resolve_target(node_id, diagram) end)
      ]
    )

    start_events_with_config = result.tasks |> Enum.map(fn config -> {Peex.Core.StartEvent, config} end)

    start_events_with_config
  end

  def parse_end_events(diagram) do

    result = diagram |> xmap(
      tasks: [
        ~x"//bpmn:endEvent"l,
        id: ~x"./@id"
      ]
    )

    end_events_with_config = result.tasks |> Enum.map(fn config -> {Peex.Core.EndEvent, config} end)

    end_events_with_config
  end

  def resolve_gateway_targets(sequence_node_ids, diagram) do

    next_nodes = sequence_node_ids |> Enum.map(fn sequence_node_id ->

      sequence_node = diagram |> xpath(~x"//bpmn:sequenceFlow[@id = \"#{sequence_node_id}\"]")

      id = sequence_node |> xpath(~x"./@targetRef")
      condition = sequence_node |> xpath(~x"./bpmn:conditionExpression/text()")

      %{id: id, condition: condition}
    end)

    sort_for_default_route(next_nodes)
  end

  @doc ~S"""
  Sort the nodes, so that the default connections is the last element

  ## Examples: 

      iex> nodes = [
        %{condition: 'token.payload.counter > 10', id: :ScriptTask_19h9wpv},
        %{condition: nil, id: :ExclusiveGateway_0btyrc3},
        %{condition: 'token.payload.counter > 1', id: :ScriptTask_19h9wpv},
        %{condition: 'token.payload.counter > 10', id: :ScriptTask_20h9wv}
      ]
      iex> sort_for_default_route(nodes)
      [
        %{condition: 'token.payload.counter > 10', id: :ScriptTask_19h9wpv},
        %{condition: 'token.payload.counter > 1', id: :ScriptTask_19h9wpv},
        %{condition: 'token.payload.counter > 10', id: :ScriptTask_20h9wv},
        %{condition: nil, id: :ExclusiveGateway_0btyrc3}
      ]
  """
  def sort_for_default_route(nodes) do
    Enum.sort_by(nodes, fn node -> node.condition == nil end)
  end

  def parse_exlusive_gateways(diagram) do

    result = diagram |> xmap(
      nodes: [
        ~x"//bpmn:exclusiveGateway"l,
        id: ~x"./@id",
        next_nodes: ~x"./bpmn:outgoing/text()"l |> transform_by(fn node_ids -> resolve_gateway_targets(node_ids, diagram) end)
      ]
    )

    join_gateways_with_config = result.nodes
      |> Enum.filter(fn config -> Enum.count(config.next_nodes) == 1 end)
      |> Enum.map(fn config -> Map.put(config, :next_node_id, List.first(config.next_nodes).id) end)
      |> Enum.map(fn config -> Map.delete(config, :next_nodes) end)
      |> Enum.map(fn config -> {Peex.Core.ExclusiveJoinGateway, config} end)

    split_gateways_with_config = result.nodes
      |> Enum.filter(fn config -> Enum.count(config.next_nodes) > 1 end)
      |> Enum.map(fn config -> {Peex.Core.ExclusiveSplitGateway, config} end)

    gateways_with_config = join_gateways_with_config ++ split_gateways_with_config

    gateways_with_config
  end

  def parse_inclusive_gateways(diagram) do

    result = diagram |> xmap(
      nodes: [
        ~x"//bpmn:inclusiveGateway"l,
        id: ~x"./@id",
        next_nodes: ~x"./bpmn:outgoing/text()"l |> transform_by(fn node_ids -> resolve_gateway_targets(node_ids, diagram) end)
      ]
    )

    join_gateways = result.nodes
      |> Enum.filter(fn config -> Enum.count(config.next_nodes) <= 1 end)

    join_ids = Enum.map(join_gateways, & &1.id)

    join_gateways_with_config = join_gateways
      |> Enum.map(fn config ->
        case config.next_nodes do
          [first | _] -> Map.put(config, :next_node_id, first.id)
          [] -> config
        end
      end)
      |> Enum.map(fn config -> Map.delete(config, :next_nodes) end)
      |> Enum.map(fn config -> {Peex.Core.InclusiveJoinGateway, config} end)

    adjacency_map = _build_adjacency_map(diagram)

    split_gateways_with_config = result.nodes
      |> Enum.filter(fn config -> Enum.count(config.next_nodes) > 1 end)
      |> Enum.map(fn config ->
        paired_join_id = _find_paired_join(config.id, adjacency_map, join_ids)
        Map.put(config, :paired_join_id, paired_join_id)
      end)
      |> Enum.map(fn config -> {Peex.Core.InclusiveSplitGateway, config} end)

    join_gateways_with_config ++ split_gateways_with_config
  end

  # BFS forward from a split gateway to find the first reachable inclusive join gateway.
  defp _find_paired_join(split_id, adjacency_map, join_ids) do
    start_targets = Map.get(adjacency_map, split_id, [])
    _bfs(start_targets, MapSet.new([split_id]), adjacency_map, join_ids)
  end

  defp _bfs([], _visited, _adjacency_map, _join_ids) do
    Logger.warning("Could not find paired inclusive join gateway")
    nil
  end

  defp _bfs(queue, visited, adjacency_map, join_ids) do
    case Enum.find(queue, fn node_id -> node_id in join_ids end) do
      nil ->
        new_visited = MapSet.union(visited, MapSet.new(queue))

        next_queue = queue
          |> Enum.flat_map(fn node_id -> Map.get(adjacency_map, node_id, []) end)
          |> Enum.reject(fn node_id -> MapSet.member?(new_visited, node_id) end)
          |> Enum.uniq()

        _bfs(next_queue, new_visited, adjacency_map, join_ids)

      found_join_id ->
        found_join_id
    end
  end

  # Build a forward adjacency map from all sequence flows: source_ref -> [target_ref, ...]
  defp _build_adjacency_map(diagram) do
    flows = diagram |> xpath(~x"//bpmn:sequenceFlow"l)

    Enum.reduce(flows, %{}, fn flow, acc ->
      source = xpath(flow, ~x"./@sourceRef")
      target = xpath(flow, ~x"./@targetRef")
      Map.update(acc, source, [target], fn targets -> targets ++ [target] end)
    end)
  end

  @spec parse(String.t()) :: any()

  def parse(file_path) do

    {:ok, diagram} = File.read(file_path)

    script_tasks = parse_script_tasks(diagram)
    service_tasks = parse_service_tasks(diagram)
    tasks = parse_tasks(diagram)
    start_events = parse_start_events(diagram)
    end_events = parse_end_events(diagram)
    exclusive_gateways = parse_exlusive_gateways(diagram)
    inclusive_gateways = parse_inclusive_gateways(diagram)

    nodes = script_tasks ++ service_tasks ++ tasks ++ start_events ++ end_events ++ exclusive_gateways ++ inclusive_gateways

    nodes
  end
end
