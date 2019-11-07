
defmodule Peex.Example.ProcessSupervisor do
  use Supervisor

  require Logger

  def start_link(state) do
    Supervisor.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(_state) do

    start_event_1_config = %{next_node_id: :ScriptTask_1}
    end_event_1_config = []

    service_task_1_config = %{next_node_id: :SplitGateway_1}

    script_task_1_config = %{
      next_node_id: :JoinGateway_1,
      script: "result = %{counter: 1}"
    }
    script_task_2_config = %{
      next_node_id: :EndEvent_1,
      script: "result = nil"
    }

    split_gateway_1_config = %{
      branches: [
        %{next_node_id: :JoinGateway_1, condition: "rem(token.payload.counter,2) == 0"},
        %{next_node_id: :ScriptTask_2, condition: "rem(token.payload.counter,2) != 0"}
      ]
    }
    join_gateway_1_config = %{next_node_id: :ServiceTask_1}

    children = [
      %{
        id: :EndEvent_1,
        start: {Peex.Core.EndEvent, :start_link, [end_event_1_config, :EndEvent_1]}
      },
      %{
        id: :ScriptTask_2,
        start: {Peex.Core.ScriptTask, :start_link, [script_task_2_config, :ScriptTask_2]}
      },
      %{
        id: :SplitGateway_1,
        start: {Peex.Core.ExclusiveSplitGateway, :start_link, [split_gateway_1_config, :SplitGateway_1]}
        },
      %{
        id: :ServiceTask_1,
        start: {Peex.Core.ServiceTask, :start_link, [service_task_1_config, :ServiceTask_1]}
      },
      %{
        id: :JoinGateway_1,
        start: {Peex.Core.ExclusiveJoinGateway, :start_link, [join_gateway_1_config, :JoinGateway_1]}
      },
      %{
        id: :ScriptTask_1,
        start: {Peex.Core.ScriptTask, :start_link, [script_task_1_config, :ScriptTask_1]}
      },
      %{
        id: :StartEvent_1,
        start: {Peex.Core.StartEvent, :start_link, [start_event_1_config, :StartEvent_1]}
      },
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

end
