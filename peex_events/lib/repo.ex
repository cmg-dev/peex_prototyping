
defmodule Peex.Events.Repo do
  use GenServer

  import AMQP

  require Logger


  def start_link(_initialState) do
    GenServer.start_link(
      __MODULE__,
      [],
      name: _global_server_name(:peex_events))
  end

  @impl true
  def init(_initialState) do

    config = Application.get_env(:peex_events, Peex.Events.Repo)

    username = config[:username]
    password = config[:password]
    hostname = config[:hostname]

    {:ok, connection} = AMQP.Connection.open("amqp://#{username}:#{password}@#{hostname}")

    {:ok, channel} = AMQP.Channel.open(connection)

    AMQP.Queue.declare(channel, "peex_monitoring", auto_delete: true)
    AMQP.Exchange.fanout(channel, "peex_exchange")
    AMQP.Queue.bind(channel, "peex_monitoring", "peex_exchange")

    {:ok, %{channel: channel}}
  end

  defp _global_server_name(server_name) do
    {:global, {:servername, server_name}}
  end

  defp _try_cast(message) do
    case GenServer.whereis(_global_server_name(:peex_events)) do
      nil ->
        {:error, :invalid_server}

      servername ->
        GenServer.cast(servername, message)
    end
  end

  def publish(message) do
    _try_cast({:publish, message})
  end

  @impl true
  def handle_cast({:publish, message}, state) do

    channel = state.channel

    encoded_message = Jason.encode!(message)

    AMQP.Basic.publish(channel, "peex_exchange", "", encoded_message)

    {:noreply, state}
  end

end
