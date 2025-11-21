defmodule Toolbox.Repo.Migrations.CreateUserPackages do
  use Ecto.Migration

  def change do
    create table(:user_packages) do
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :package_id, references(:packages, on_delete: :delete_all), null: false
      add :following, :boolean, default: false, null: false

      timestamps()
    end

    create unique_index(:user_packages, [:user_id, :package_id])
  end
end
