defmodule Peex.MkITest do
  use ExUnit.Case, async: true

  require Logger

  setup do
    {:ok, server_pid} = MkISupervisor.start_link([])

    :sys.statistics(server_pid, true)
    :sys.trace(server_pid, true)

    {:ok, server: server_pid}
  end

  test "supervisor restarts GenServer after it dies" do
    Logger.debug "Starting test #1"
    token = [1002]
    assert :ok == MkIStartEvent.start(:MkI_startevent_1, token)

    :timer.sleep(500)

  end
end
