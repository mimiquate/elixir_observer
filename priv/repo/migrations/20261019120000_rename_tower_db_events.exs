defmodule Toolbox.Repo.Migrations.RenameTowerDbEvents do
  use Ecto.Migration

  def up do
    execute("ALTER TABLE IF EXISTS tower_db_events RENAME TO tower_web_events")

    execute(
      "ALTER INDEX IF EXISTS tower_db_events_pkey RENAME TO tower_web_events_pkey"
    )

    execute(
      "ALTER INDEX IF EXISTS tower_db_events_datetime_index RENAME TO tower_web_events_datetime_index"
    )

    execute(
      "ALTER INDEX IF EXISTS tower_db_events_level_index RENAME TO tower_web_events_level_index"
    )

    execute(
      "ALTER INDEX IF EXISTS tower_db_events_normalized_reason_gin_trgm_ops_index RENAME TO tower_web_events_normalized_reason_gin_trgm_ops_index"
    )

    execute("""
      ALTER INDEX IF EXISTS "tower_db_events_similarity_id_datetime_DESC_index"
      RENAME TO "tower_web_events_similarity_id_datetime_DESC_index"
    """)

    TowerWeb.DB.Migration.up(from: 0, to: 3)

    alter table(:tower_web_events) do
      add_if_not_exists(:request_data, :map)
    end
  end

  def down do
    TowerWeb.DB.Migration.down(from: 3, to: 0)
  end
end
