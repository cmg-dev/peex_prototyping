defmodule Contracts.ProcessToken do
  use Ecto.Schema

  schema "processtoken" do
    field :process_instance_id, :string
    field :process_model_id, :string
    field :correlation_id, :string
    field :created_at, :utc_datetime
    field :updated_at, :utc_datetime
    field :flow_node_instance_id, :string
    field :identity, :string
    field :parent_caller, :string
    field :payload, :map
  end
end
