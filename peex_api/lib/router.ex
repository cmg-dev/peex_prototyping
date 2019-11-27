defmodule Peex.API.Router do
  use Plug.Router

  alias Peex.Core.BPMNParser

  import SweetXml

  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Peex API")
  end

  get "/processes" do

    file_path = "../data/processes/example_process.bpmn"

    {:ok, process_definition} = File.read(file_path)

    process_id = process_definition
    |> xpath(~x"//bpmn:collaboration/@id")
    |> List.to_string

    start_events = BPMNParser.parse_start_events(process_definition)

    start_event_ids = start_events |> Enum.map(fn {_, start_event} -> start_event.id |> List.to_string end)

    processes = [
      %{id: process_id, start_events: start_event_ids},
    ]

    response = Jason.encode!(processes)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, response)
  end

  get "/processes/:process_id/definition" do

    file_path = "../data/processes/example_process.bpmn"

    {:ok, process_definition} = File.read(file_path)

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, process_definition)
  end

  post "/processes/:process_id/start/:start_event_id" do

    file_path = "../data/processes/example_process.bpmn"

    nodes_with_config = Peex.Core.BPMNParser.parse(file_path)

    {:ok, server_pid} = Peex.Core.ProcessSupervisor.start_link(nodes_with_config)

    start_event = String.to_existing_atom(start_event_id)

    token = %Peex.Contracts.Processtoken{
      process_model_id: process_id,
      correlation_id: to_string(DateTime.utc_now()),
      identity: Base.encode64("dummy_token"),
      parent_caller_instance_id: nil,
    }

    Peex.Core.StartEvent.start(start_event, token)

    :timer.sleep(1000)

    send_resp(conn, 200, "Process #{process_id} started")
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
