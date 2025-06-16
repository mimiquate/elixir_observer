defmodule ElixirObserver.Repo.Migrations.AddCategoryIdToPackages do
  use Ecto.Migration

  def change do
    alter table(:packages) do
      add :category_id, :integer
    end

    create index(:packages, [:category_id])
  end
end
