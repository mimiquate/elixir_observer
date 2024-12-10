defmodule Toolbox.Repo.Migrations.CreatePackages do
  use Ecto.Migration

  def change do
    create table(:packages) do
      add(:name, :string)

      timestamps(type: :utc_datetime)
    end

    create table(:hexpm_snapshots) do
      add(:package_id, references(:packages))
      add(:data, :map)

      timestamps(type: :utc_datetime)
    end

    create table(:github_snapshots) do
      add(:package_id, references(:packages))
      add(:data, :map)

      timestamps(type: :utc_datetime)
    end
  end
end
