defmodule Toolbox.Package.HexpmVersion do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :version, :string
    field :elixir_requirement, :string

    embeds_many :required, Toolbox.Profile.HexmRequirement, on_replace: :delete do
      field :name, :string
      field :requirement, :string
    end

    embeds_many :optional, Toolbox.Profile.HexmRequirement, on_replace: :delete

    embeds_one :retirement, Toolbox.Profile.HexmRetirment, on_replace: :delete do
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
    |> cast_embed(:required_requirements, with: &requirement_changeset/2)
    |> cast_embed(:optional_requirements, with: &requirement_changeset/2)
  end

  def retirement_changeset(retirement, attrs \\ %{}) do
    retirement
    |> cast(attrs, [:message, :reason])
    |> validate_required([:message, :reason])
  end

  def requirement_changeset(requirement, attrs \\ %{}) do
    requirement
    |> cast(attrs, [:name, :requirement])
    |> validate_required([:name, :requirement])
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
