defmodule Toolbox.Tasks.Category do
  alias Toolbox.Packages

  require Logger

  @instructions "Which category best describes the primary purpose of the package in `name`, given its `description`? Pick the most specific one."

  def categorize(%Toolbox.Package{} = package, opts \\ []) do
    log_on_update = Keyword.get(opts, :log_on_update, false)

    with {:ok, choice} <- classify(package) do
      category = choice |> String.to_integer() |> Packages.get_category_by_id!()

      put_category(package, category, log_on_update)
    end
  end

  defp put_category(%{category: category}, category, _log), do: :ok

  defp put_category(package, category, log_on_update) do
    with {:ok, _updated} <- Packages.update_package_category(package, %{category: category}) do
      if log_on_update do
        Logger.warning(
          "recategorized #{package.name}: #{category_name(package.category)} -> #{category.name}"
        )
      end

      :ok
    end
  end

  defp classify(package) do
    request =
      Req.new(
        url: "#{base_url()}/v1/systemone",
        auth: {:bearer, api_key()},
        json: body(package),
        receive_timeout: 10_000
      )

    case Req.post(request) do
      {:ok, %{status: 200, body: %{"answers" => %{"category" => %{"choice" => choice}}}}} ->
        {:ok, choice}

      {:ok, %{status: status}} when status in [408, 429] ->
        {:error, "Failed to classify package #{package.name} with status #{status}"}

      {:ok, %{status: status}} when status in 400..499 ->
        {:skip, "Unable to classify package #{package.name} with status #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp body(package) do
    %{
      model: "jev-latest",
      state: %{
        name: package.name,
        description: package.description || "",
        docs_url: "https://hexdocs.pm/#{package.name}"
      },
      questions: %{
        category: %{
          type: "choice",
          instructions: @instructions,
          criteria: categories_as_map()
        }
      }
    }
  end

  defp categories_as_map do
    Map.new(Toolbox.Category.all(), fn category ->
      {Integer.to_string(category.id), describe_category(category)}
    end)
  end

  defp describe_category(%{notes: nil} = category),
    do: "#{category.name}: #{category.description}"

  defp describe_category(category),
    do: "#{category.name}: #{category.description}. Notes: #{category.notes}"

  defp category_name(nil), do: "none"
  defp category_name(category), do: category.name

  if Mix.env() == :test do
    defp base_url, do: ProcessTree.get({__MODULE__, :base_url})
  else
    defp base_url, do: Application.fetch_env!(:toolbox, :jev_base_url)
  end

  defp api_key, do: Application.fetch_env!(:toolbox, :jev_api_key)
end
