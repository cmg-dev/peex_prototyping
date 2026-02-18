defmodule Peex.InclusiveGateway.Test do
  use ExUnit.Case, async: false

  require Logger

  setup do
    case Process.whereis(Peex.Core.ProcessSupervisor) do
      nil ->
        :ok

      pid ->
        Process.exit(pid, :kill)
        :timer.sleep(50)
    end

    nodes_with_config = Peex.Core.BPMNParser.parse("processes/mk_ii/feedback_volker_joingw.bpmn")

    {:ok, server_pid} = Peex.Core.ProcessSupervisor.start_link(nodes_with_config)

    {:ok, server: server_pid}
  end

  test "Inclusive join fires when all forked paths reach the join (default route)" do
    token = %Contracts.Processtoken{
      process_model_id: "Process_0k9zq6b",
      correlation_id: to_string(DateTime.utc_now()),
      identity: Base.encode64("inclusive_test_both_paths"),
      parent_caller_instance_id: nil,
      payload: %{"a" => 1, "b" => 2}
    }

    assert :ok == Peex.Core.StartEvent.start(:StartEvent_1, token)

    :timer.sleep(1000)
  end

  test "Inclusive join fires when one path is consumed by End Event X" do
    token = %Contracts.Processtoken{
      process_model_id: "Process_0k9zq6b",
      correlation_id: to_string(DateTime.utc_now()),
      identity: Base.encode64("inclusive_test_one_path_end_event"),
      parent_caller_instance_id: nil,
      payload: %{"a" => 1, "b" => 1}
    }

    assert :ok == Peex.Core.StartEvent.start(:StartEvent_1, token)

    :timer.sleep(1000)
  end
end
