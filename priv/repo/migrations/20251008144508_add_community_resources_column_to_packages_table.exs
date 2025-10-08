defmodule Toolbox.Repo.Migrations.AddCommunityResourcesColumnToPackagesTable do
  use Ecto.Migration

  def change do
    alter table("packages") do
      add :community_resources, :map
    end
  end
end
