defmodule Toolbox.Repo.Migrations.AddTowerWebIssues do
  use Ecto.Migration

  def up, do: TowerWeb.DB.Migration.up(from: 1, to: 3)
  def down, do: TowerWeb.DB.Migration.down(from: 3, to: 1)
end
