defmodule Toolbox.Repo.Migrations.AddDescriptionGinIndexToPackages do
  use Ecto.Migration

  def change do
    # Enable the pg_trgm extension for trigram support
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm;"

    # Add GIN index with trigrams for efficient ILIKE searches on description
    execute "CREATE INDEX packages_description_gin_idx ON packages USING gin (description gin_trgm_ops);"
  end
end
