defmodule MkISupervisor do
  # Automatically defines child_spec/1
  use Supervisor

  require Logger

  def start_link(token) do
    Supervisor.start_link(__MODULE__, token, name: __MODULE__)
  end

  def init(token) do

    script_task_1_config = ''
    script_task_2_config = ''

    children = [
      %{
        id: :MkI_endevent_1,
        start: {MkIEndEvent, :start_link, [[], :MkI_endevent_1]}
      },
      %{
        id: :MkI_scripttask_2,
        start: {MkIScriptTask, :start_link, [[:MkI_endevent_1, script_task_2_config], :MkI_scripttask_2]}
      },
      %{
        id: :MkI_splitgateway_1,
        start: {MkIExclusiveSplitGateway, :start_link, [[:MkI_joingateway_1, :MkI_scripttask_2], :MkI_splitgateway_1]}
      },
      %{
        id: :MkI_joingateway_1,
        start: {MkIExclusiveJoinGateway, :start_link, [[:MkI_servicetask_1], :MkI_joingateway_1]}
      },
      %{
        id: :MkI_servicetask_1,
        start: {MkIServiceTask, :start_link, [[:MkI_splitgateway_1], :MkI_servicetask_1]}
      },
      %{
        id: :MkI_scripttask_1,
        start: {MkIScriptTask, :start_link, [[:MkI_joingateway_1, script_task_1_config], :MkI_scripttask_1]}
      },
      %{
        id: :MkI_startevent_1,
        start: {MkIStartEvent, :start_link, [[:MkI_scripttask_1], :MkI_startevent_1]}
      },
    ]

    # Now we start the supervisor with the children and a strategy
    Supervisor.init(children, strategy: :one_for_one)
  end

end
