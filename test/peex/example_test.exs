
defmodule Peex.Example.Test do
  use ExUnit.Case, async: true

  require Logger

  setup do

    nodes_with_config = Peex.Core.BPMNParser.parse("processes/example/example_process.bpmn")

    {:ok, server_pid} = Peex.Core.ProcessSupervisor.start_link(nodes_with_config)

    :sys.statistics(server_pid, true)
    :sys.trace(server_pid, true)

    {:ok, server: server_pid}
  end

  test "supervisor restarts GenServer after it dies" do

    Logger.debug "Starting test #1"

    token = %{instance_id: 100, payload: nil}

    assert :ok == Peex.Core.StartEvent.start(:StartEvent_1, token)

    :timer.sleep(500)
  end
end
