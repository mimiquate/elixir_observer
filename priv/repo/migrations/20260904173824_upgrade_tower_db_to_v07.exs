defmodule Toolbox.Repo.Migrations.UpgradeTowerDbToV07 do
  use Ecto.Migration

  def up, do: TowerDB.Migration.up(from: 5, to: 7)
  def down, do: TowerDB.Migration.down(from: 7, to: 5)
end
