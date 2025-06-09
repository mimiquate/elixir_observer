defmodule Toolbox.Package.HexpmVersion do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :version, :string
    field :elixir_requirement, :string

    embeds_many :required, Toolbox.Package.HexpmRequirement, on_replace: :delete
    embeds_many :optional, Toolbox.Package.HexpmRequirement, on_replace: :delete

    embeds_one :retirement, Toolbox.Package.HexmRetirment, on_replace: :delete do
      field :message, :string
      field :reason, :string
    end

    field :published_at, :utc_datetime
    field :published_by_username, :string
    field :published_by_email, :string
  end

  def changeset(hexpm_version, attrs) do
    hexpm_version
    |> cast(attrs, [
      :version,
      :elixir_requirement,
      :published_at,
      :published_by_username,
      :published_by_email
    ])
    |> validate_required([:version, :published_at, :published_by_username])
    |> cast_embed(:retirement, with: &retirement_changeset/2)
    |> cast_embed(:required)
    |> cast_embed(:optional)
  end

  def retirement_changeset(retirement, attrs \\ %{}) do
    retirement
    |> cast(attrs, [:message, :reason])
    |> validate_required([:message, :reason])
  end

  # Build a map from Hexpm release response
  def build_version_from_api_response(data) do
    {required, optional} =
      data["requirements"]
      |> Enum.map(fn {name, data} ->
        %{
          name: name,
          optional: data["optional"],
          requirement: data["requirement"]
        }
      end)
      |> Enum.split_with(fn r -> not r.optional end)

    %{
      version: data["version"],
      elixir_requirement: data["meta"]["elixir"],
      retirement: data["retirement"],
      required: required,
      optional: optional,
      published_at: data["inserted_at"],
      published_by_username: data["publisher"]["username"],
      published_by_email: data["publisher"]["email"]
    }
  end
end
