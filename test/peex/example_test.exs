
defmodule Peex.Example.Test do
  use ExUnit.Case, async: true

  require Logger

  setup do

    {:ok, server_pid} = Peex.Example.ProcessSupervisor.start_link([])

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