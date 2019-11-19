defmodule Peex.ContractsTest do
  use ExUnit.Case
  doctest Peex.Contracts

  test "greets the world" do
    assert Peex.Contracts.hello() == :world
  end
end
