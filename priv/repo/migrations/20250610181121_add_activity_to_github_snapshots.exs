defmodule Toolbox.Repo.Migrations.AddActivityToGithubSnapshots do
  use Ecto.Migration

  def change do
    alter table(:github_snapshots) do
      add :activity, :map
    end
  end
end
