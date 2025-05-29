defmodule Toolbox.Repo.Migrations.AddNameIndexToPackages do
  use Ecto.Migration

  def change do
    create unique_index(:packages, :name)
  end
end
