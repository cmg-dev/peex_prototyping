defmodule Peex.MkI do

  require Logger

  @moduledoc """
  Documentation for Peex.MkI.
  """

  def start_process_model do
    # parsed_process_diagram = load_xml()

    # actors_needed = get_actors_from_diagram(parsed_process_diagram)

    # actor_relation = get_relations_from_diagram
    # children = [
    #   %{
    #     id: :seven021M,
    #     start: {ServiceTask, :start_link, [[new_node_name, config], :flow_node_instance_id]}
    #   },
    #   %{
    #     id: :seven122M,
    #     start: {TableServerSeven, :start_link, [[1_000_000, 2_000_000], :seven122M]}
    #   }
    # ]


    # build_supervisor(actors_needed, actor_relation)
  end

  @doc """
  Hello world.

  ## Examples

      iex> Peex.MkI.hello()
      :world

  """
  def hello_world do
    Logger.debug "Starting"
    {:ok, server_pid} = MkISupervisor.start_link([])
    {:ok, server: server_pid}

    token = [1002]
    MkIStartEvent.start(:MkI_startevent_1, token)
  end
end
