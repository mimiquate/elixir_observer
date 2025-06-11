defmodule Toolbox.GithubSnapshot.PullRequest do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :permalink, :string
    field :created_at, :utc_datetime
    field :title, :string
    field :merged_at, :utc_datetime
    field :merged_by_login, :string
    field :merged_by_avatar_url, :string
  end

  def changeset(pr, attrs) do
    fields = [
      :permalink,
      :created_at,
      :title,
      :merged_at,
      :merged_by_avatar_url,
      :merged_by_login
    ]

    pr
    |> cast(attrs, fields)
    |> validate_required(fields)
  end
end
