defmodule Peex.APITest do
  use ExUnit.Case
  doctest Peex.API

  test "greets the world" do
    assert Peex.API.hello() == :world
  end
end
