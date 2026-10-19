defmodule Toolbox.Repo.Migrations.RenameTowerDbEvents do
  use Ecto.Migration

  def up do
    execute("ALTER TABLE IF EXISTS tower_db_events RENAME TO tower_web_events")

    alter table(:tower_web_events) do
      add_if_not_exists(:request_data, :map)
    end
  end

  def down do
    alter table(:tower_web_events) do
      remove_if_exists(:request_data, :map)
    end

    execute("ALTER TABLE IF EXISTS tower_web_events RENAME TO tower_db_events")
  end
end
