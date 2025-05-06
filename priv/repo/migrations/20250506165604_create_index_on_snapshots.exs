defmodule Toolbox.Repo.Migrations.CreateIndexOnSnapshots do
  use Ecto.Migration
  @disable_migration_lock true
  @disable_ddl_transaction true

  def change do
    create index(:hexpm_snapshots, ["package_id, id DESC"], concurrently: true)
    create index(:github_snapshots, ["package_id, id DESC"], concurrently: true)
  end
end
