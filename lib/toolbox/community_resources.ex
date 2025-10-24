defmodule Toolbox.CommunityResources do
  alias Toolbox.Package
  alias Toolbox.Package.CommunityResource
  alias Ecto.Changeset

  defmodule Parser do
    def parse(blob) do
      json = Jason.decode!(blob)

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
    end
  end

  defmodule Loader do
    def load(path) do
      for file_name <- Path.wildcard(Path.expand(path)), into: %{} do
        package_name = Path.basename(file_name, ".json")

        resources =
          file_name
          |> File.read!()
          |> Parser.parse()

        {package_name, resources}
      end
    end
  end

  @resources Path.join([
               Application.app_dir(:toolbox),
               Application.compile_env!(:toolbox, [Toolbox.CommunityResources, :path])
             ])
             |> Loader.load()

  @spec find_by_package(Package.t()) :: [CommunityResource.t()]
  def find_by_package(%Package{name: name}) do
    Map.get(@resources, name, [])
  end
end
