
defmodule Peex.Example.Service do

  def increment_counter(token) do

    current_value = token.payload.counter

    %{ counter: current_value + 1 }
  end
end
