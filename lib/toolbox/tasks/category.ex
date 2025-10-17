defmodule Toolbox.Tasks.Category do
  require Logger

  def run(packages) when is_list(packages) do
    prompt = """
      You are an Elixir/Hex package classification expert. Your task is to classify the given Elixir package into exactly ONE of the predefined categories below.

      **Categories:** - ID | NAME | DESCRIPTION
      #{for category <- Toolbox.Category.all(), into: "" do
      "- #{category.id} | #{category.name} | #{category.description} \n"
    end}

      **Instructions:**
      1. Analyze the package's primary purpose and functionality in the Elixir/OTP ecosystem
      2. Consider the package's main use case in typical Elixir/Phoenix applications
      3  Read the package documentation
      3. If a package could fit multiple categories, choose the MOST SPECIFIC and PRIMARY category
      4. Consider Elixir-specific patterns like GenServers, supervisors, and OTP principles
      5. Base your classification on the package's core functionality, not secondary features

      **Input**
      Package Name: [package_name]
      Description: [brief description if available]
      Documentation Link: [link to documentation if available]

      **Output::**
      id, category and reasoning of the selected category

      **Example:**
      **Input**
      Package Name: guardian
      Description: An authentication framework for use with Elixir applications
      Documentation: https://hexdocs.pm/guardian


      **Output**
      "package_name": guardian
      "id": 1,
      "category": "Authentication/Authorization",
      "reasoning": "Guardian's primary purpose is handling JWT-based authentication and authorization in Elixir applications."

      Now classify these packages:

      #{for package <- packages, into: "" do
      """
        Package Name: #{package.name}
        Description: #{package.description}
        Documentation: https://hexdocs.pm/#{package.name}

      """
    end}
    """

    body = %{
      contents: [
        %{
          parts: [
            %{
              text: prompt
            }
          ]
        }
      ],
      generationConfig: %{
        responseMimeType: "application/json",
        responseSchema: %{
          type: "ARRAY",
          items: %{
            type: "OBJECT",
            properties: %{
              name: %{type: "STRING"},
              category: %{
                type: "OBJECT",
                properties: %{
                  id: %{type: "INTEGER"},
                  name: %{type: "STRING"},
                  reasoning: %{type: "STRING"}
                },
                propertyOrdering: ["id", "name", "reasoning"]
              }
            },
            propertyOrdering: ["name", "category"]
          }
        }
      }
    }

    {:ok, response} =
      Req.post("#{base_url()}/v1beta/models/gemini-2.5-flash:generateContent",
        headers: [
          {"x-goog-api-key", "#{api_key()}"},
          {"user-agent", "elixir client"}
        ],
        json: body,
        receive_timeout: 120_000
      )

    response = response.body

    %{"candidates" => [%{"content" => %{"parts" => [%{"text" => text}]}}]} = response
    json = JSON.decode!(text)

    result =
      Enum.into(json, %{}, fn %{"name" => name, "category" => category} ->
        {name, category}
      end)

    for package <- packages do
      category = Toolbox.Packages.get_category_by_id!(result[package.name]["id"])
      Toolbox.Packages.update_package_category(package, %{category: category})
    end
  end

  def run(packages) do
    run([packages])
  end

  def base_url() do
    Application.fetch_env!(:toolbox, :gemini_base_url)
  end

  def api_key() do
    Application.fetch_env!(:toolbox, :gemini_api_key)
  end
end
