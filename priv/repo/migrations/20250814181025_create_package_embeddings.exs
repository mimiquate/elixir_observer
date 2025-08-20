defmodule Toolbox.Repo.Migrations.CreatePackageEmbeddings do
  use Ecto.Migration

  def change do
    create table(:package_embeddings) do
      add(:package_id, references(:packages, on_delete: :delete_all), null: false)
      add(:embedding, :vector, size: 768, null: false)

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:package_embeddings, [:package_id]))
  end
end
