defmodule Toolbox.Repo.Migrations.UpdateLatestHexpmTrigger do
  use Ecto.Migration

  def up do
    execute """
      CREATE OR REPLACE FUNCTION refresh_latest_hexpm_snapshots()
      RETURNS TRIGGER LANGUAGE plpgsql
      AS $$
      BEGIN
      IF current_setting('toolbox.skip_refresh_latest_hexpm_snapshots', TRUE) = 'on' THEN
        RETURN NULL;
      END IF;

      REFRESH MATERIALIZED VIEW CONCURRENTLY latest_hexpm_snapshots;
      RETURN NULL;
      END $$;
    """
  end
end
