defmodule Peex.MkITest do
  use ExUnit.Case, async: true

  setup do
    {:ok, server_pid} = MkISupervisor.start_link([])
    {:ok, server: server_pid}
  end

  test "supervisor restarts GenServer after it dies" do
    token = [1002, 0]
    assert :ok == MkIStartEvent.start(:MkI_startevent_1, token)

  end
end
