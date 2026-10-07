defmodule Toolbox.Tasks.Category do
  alias Toolbox.Packages

  @instructions "Which category best describes the primary purpose of the package in `name`, given its `description`? Pick the most specific one."

  # Same policy as Typesafe's SDK: 408, 429 and any 5xx (Jev's 529 included).
  # `retry: :transient` is not used because it leaves out the 529.
  defguardp is_transient_status(status) when status in [408, 429] or status in 500..599

  def run(%Toolbox.Package{} = package) do
    case classify(package) do
      {:ok, choice} ->
        category = choice |> String.to_integer() |> Packages.get_category_by_id!()

        if package.category == category do
          {:ok, package}
        else
          Packages.update_package_category(package, %{category: category})
        end

      {:error, _reason} = error ->
        error
    end
  end

  defp classify(package) do
    request =
      Req.new(
        url: "#{base_url()}/v1/systemone",
        auth: {:bearer, api_key()},
        json: body(package),
        receive_timeout: 10_000,
        retry: &retry?/2,
        max_retries: 2
      )

    case Req.post(request) do
      {:ok, %{status: 200, body: %{"answers" => %{"category" => %{"choice" => choice}}}}} ->
        {:ok, choice}

      {:ok, %{status: status}} when is_transient_status(status) ->
        {:error, {:http_status, status}}

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
          criteria: criteria()
        }
      }
    }
  end

  defp criteria do
    Map.new(Toolbox.Category.all(), fn category ->
      {Integer.to_string(category.id), "#{category.name}: #{category.description}"}
    end)
  end

  defp retry?(_request, %Req.Response{status: status}), do: is_transient_status(status)

  defp retry?(_request, %Req.TransportError{reason: reason}),
    do: reason in [:timeout, :econnrefused, :closed]

  defp retry?(_request, _other), do: false

  if Mix.env() == :test do
    defp base_url, do: ProcessTree.get({__MODULE__, :base_url})
  else
    defp base_url, do: Application.fetch_env!(:toolbox, :jev_base_url)
  end

  defp api_key, do: Application.fetch_env!(:toolbox, :jev_api_key)
end
