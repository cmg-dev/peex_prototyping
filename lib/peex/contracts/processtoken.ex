defmodule Peex.Processtoken do
  use Ecto.Schema

  import Ecto.Changeset

  schema "processtoken" do
    field :process_instance_id, Ecto.UUID, default: Ecto.UUID.generate()
    field :process_model_id, :string
    field :correlation_id, :string
    field :created_at, :utc_datetime, default: DateTime.utc_now()
    field :updated_at, :utc_datetime, default: DateTime.utc_now()
    field :flow_node_instance_id, :string
    field :identity, :string
    field :parent_caller_instance_id, Ecto.UUID
    field :payload, :map, default: {}
  end

end
