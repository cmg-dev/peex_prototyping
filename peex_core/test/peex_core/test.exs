defmodule Peex.Core.Test do
  use ExUnit.Case, async: true

  require Logger

  setup do

    nodes_with_config = Peex.Core.BPMNParser.parse("../data/processes/example_process.bpmn")

    {:ok, server_pid} = Peex.Core.ProcessSupervisor.start_link(nodes_with_config)

    :sys.statistics(server_pid, true)
    :sys.trace(server_pid, true)

    {:ok, server: server_pid}
  end

  test "Supervisor for 'example_process.bpmn' is reaching the EndEvent" do

    token = %Peex.Contracts.Processtoken{
      process_model_id: "Collaboration_1ti1prd",
      correlation_id: to_string(DateTime.utc_now()),
      identity: Base.encode64("dummy_token"),
      parent_caller_instance_id: nil,
    }

    assert :ok == Peex.Core.StartEvent.start(:StartEvent_1, token)

    :timer.sleep(500)
  end
end
