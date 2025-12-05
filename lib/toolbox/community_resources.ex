defmodule Toolbox.CommunityResources do
  alias Toolbox.Package
  alias Toolbox.Package.CommunityResource
  alias Ecto.Changeset

  defmodule Parser do
    def parse(blob, file) do
      json = Jason.decode!(blob)

      resources =
        Enum.map(json["resources"], fn resource_attrs ->
          %CommunityResource{}
          |> CommunityResource.changeset(resource_attrs)
          |> Changeset.apply_action(:validate)
          |> case do
            {:ok, data} ->
              data

            {:error, changeset} ->
              raise "Error loading Community Resources from JSON file. Errors: #{inspect(changeset.errors)}"
          end
        end)

      {Path.basename(file, ".json"), resources}
    end
  end

  Module.register_attribute(__MODULE__, :raw_resources, accumulate: true)

  for file <-
        Path.join(["community_resources", "*.json"])
        |> Path.relative_to_cwd()
        |> Path.expand()
        |> Path.wildcard() do
    @external_resource file
    @raw_resources file |> File.read!() |> Parser.parse(file)
  end

  @resources Enum.into(@raw_resources, %{})

  Module.delete_attribute(__MODULE__, :raw_resources)

  @spec find_by_package(Package.t()) :: [CommunityResource.t()]
  def find_by_package(%Package{name: name}) do
    Map.get(@resources, name, [])
  end
end
