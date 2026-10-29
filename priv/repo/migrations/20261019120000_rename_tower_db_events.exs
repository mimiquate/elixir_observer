defmodule Toolbox.Repo.Migrations.RenameTowerDbEvents do
  use Ecto.Migration

  def up do
    execute("ALTER TABLE IF EXISTS tower_db_events RENAME TO tower_web_events")

    TowerWeb.DB.Migration.up(from: 0, to: 3)

    alter table(:tower_web_events) do
      add_if_not_exists(:request_data, :map)
    end
  end

  def down do
    TowerWeb.DB.Migration.down(from: 3, to: 0)
  end
end
