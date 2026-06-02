defmodule Toolbox.Repo.Migrations.AddTowerDb do
  use Ecto.Migration

  def up, do: TowerDB.Migration.up()
  def down, do: TowerDB.Migration.down()
end
