defmodule Toolbox.Repo.Migrations.AddHexpmLatestStableVersionToPackages do
  use Ecto.Migration

  def change do
    alter table(:packages) do
      add :hexpm_latest_stable_version_data, :map
    end
  end
end
