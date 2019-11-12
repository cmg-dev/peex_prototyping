defmodule Peex.Processtoken.Repo.Migrations.CreateProcesstokens do
  use Ecto.Migration

  def up do
    create table(:processtokens) do
      add :process_instance_id, :string, size: 36, null: false
      add :process_model_id, :string, null: false
      add :correlation_id, :string, null: false 
      add :created_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
      add :flow_node_instance_id, :string, null: false
      add :identity, :string, null: false
      add :parent_caller_instance_id, :string, size: 36
      add :payload, :map, default: nil
    end
  end

  def down do
	drop table(:processtokens)
  end

end
