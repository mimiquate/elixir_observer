defmodule Toolbox.Repo.Migrations.UpgradeTowerDbToV08 do
  use Ecto.Migration

  def up, do: TowerDB.Migration.up(from: 7, to: 8)
  def down, do: TowerDB.Migration.down(from: 8, to: 7)
end
