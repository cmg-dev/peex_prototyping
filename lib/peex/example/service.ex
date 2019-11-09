
defmodule Peex.Example.Service do

  def increment_counter(token) do

    current_value = token.payload.counter

    new_payload = %{ counter: current_value + 1 }

    new_payload
  end
end
