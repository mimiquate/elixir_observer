defmodule Toolbox.Repo.Migrations.CreateLatestHexpmSnapshotsMaterializedView do
  use Ecto.Migration

  def up do
    execute """
    CREATE MATERIALIZED VIEW latest_hexpm_snapshots AS
    SELECT DISTINCT ON (package_id)
      id,
      package_id,
      data,
      (data#>>'{downloads,recent}')::int as recent_downloads,
      inserted_at,
      updated_at
    FROM hexpm_snapshots
    ORDER BY package_id, id DESC
    """

    execute """
      CREATE OR REPLACE FUNCTION refresh_latest_hexpm_snapshots()
      RETURNS TRIGGER LANGUAGE plpgsql
      AS $$
      BEGIN
      REFRESH MATERIALIZED VIEW CONCURRENTLY latest_hexpm_snapshots;
      RETURN NULL;
      END $$;
    """

    execute """
      CREATE OR REPLACE TRIGGER refresh
      AFTER INSERT OR UPDATE OR DELETE OR TRUNCATE
      ON hexpm_snapshots
      FOR EACH STATEMENT
      EXECUTE PROCEDURE refresh_latest_hexpm_snapshots();
    """

    create unique_index(:latest_hexpm_snapshots, [:package_id])
    create index(:latest_hexpm_snapshots, desc_nulls_last: :recent_downloads)
  end

  def down do
    execute "DROP TRIGGER IF EXISTS refresh ON hexpm_snapshots"
    execute "DROP FUNCTION IF EXISTS refresh_latest_hexpm_snapshots"
    execute "DROP MATERIALIZED VIEW IF EXISTS latest_hexpm_snapshots"
  end
end
