defmodule Contracts.Processtoken do
  use Ecto.Schema

  import Ecto.Changeset

  schema "processtokens" do
    field :process_instance_id, Ecto.UUID, default: to_string(Ecto.UUID.generate())
    field :process_model_id, :string
    field :correlation_id, :string
    field :created_at, :utc_datetime, default: DateTime.truncate(DateTime.utc_now, :second)
    field :updated_at, :utc_datetime, default: DateTime.truncate(DateTime.utc_now, :second)
    field :flow_node_instance_id, :string
    field :identity, :string
    field :parent_caller_instance_id, Ecto.UUID
    field :payload, :map, default: %{}
  end

  def changeset(token, params \\ %{}) do
    token
    |> cast(params, [:flow_node_instance_id, :parent_caller_instance_id, :payload])
  end

end
