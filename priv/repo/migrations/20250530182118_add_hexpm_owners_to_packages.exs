defmodule Toolbox.Repo.Migrations.AddHexpmOwnersToPackages do
  use Ecto.Migration

  def change do
    alter table(:packages) do
      add :hexpm_owners_sync_at, :utc_datetime
      add :hexpm_owners, :map
    end
  end
end
