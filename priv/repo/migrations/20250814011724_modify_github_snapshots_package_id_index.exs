defmodule Toolbox.Repo.Migrations.ModifyGithubSnapshotsPackageIdIndex do
  use Ecto.Migration
  @disable_migration_lock true
  @disable_ddl_transaction true

  def change do
    drop index(:github_snapshots, ["package_id, id DESC"], concurrently: true)
    create unique_index(:github_snapshots, :package_id, concurrently: true)
  end
end
