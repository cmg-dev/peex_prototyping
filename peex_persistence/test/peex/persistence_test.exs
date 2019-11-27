defmodule Peex.PersistenceTest do
  use ExUnit.Case
  doctest Peex.Persistence

  test "greets the world" do
    assert Peex.Persistence.hello() == :world
  end
end
