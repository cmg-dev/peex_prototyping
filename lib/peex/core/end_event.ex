
defmodule Peex.Core.EndEvent do
  use Peex.Core.FlowNode

  require Logger

  def handle_cast({:on_enter, token}, state) do

    _persist_on_enter(token, state, "")

    Logger.debug "#{__MODULE__} End event reached"
    Logger.debug "#{__MODULE__} token: #{inspect(token)}"

    Enum.each(token.markers || [], fn marker ->
      Logger.debug("#{__MODULE__} Notifying join #{marker.join_id}: token not coming (instance=#{token.process_instance_id})")
      _try_cast(marker.join_id, {:token_not_coming, marker.expected, token.process_instance_id})
    end)

    {:noreply, state}
  end
end
