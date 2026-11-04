defmodule Toolbox.Repo.Migrations.UpgradeTowerWebV04 do
  use Ecto.Migration

  def up, do: TowerWeb.DB.Migration.up(from: 3, to: 4)
  def down, do: TowerWeb.DB.Migration.down(from: 4, to: 3)
end
