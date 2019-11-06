defmodule Peex.MkITest do
  use ExUnit.Case
  doctest Peex.MkI

  test "greets the world" do
    assert Peex.MkI.hello() == :world
  end
end
