defmodule Toolbox.Repo.Migrations.ObanV14 do
  use Ecto.Migration

  def up do
    Oban.Migration.up(version: 14)
  end

  def down do
    Oban.Migration.down(version: 14)
  end
end
