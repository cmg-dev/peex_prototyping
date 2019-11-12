defmodule Peex.Processtoken.Repo.Migrations.AddDefaultToProcesstokens do
  use Ecto.Migration

  def up do
    alter table(:processtokens) do
      modify :updated_at, :utc_datetime, default: fragment("now()")
    end
  end

  def down do
    alter table(:processtokens) do
      modify :updated_at, :utc_datetime, null: false
    end
  end
end
