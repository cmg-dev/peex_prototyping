defmodule Peex.Processtoken.Repo.Migrations.AddFlowNodeIdToProcesstoken do
  use Ecto.Migration

  def change do
    alter table(:processtokens) do
      add :flow_node_id, :string, null: false
    end
  end
end
