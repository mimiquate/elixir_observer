defmodule Toolbox.Tasks.Embedding do
  use Nebulex.Caching, cache: Toolbox.Cache

  def calculate_query(term) do
    body = %{
      content: %{
        parts: [
          %{
            text: term
          }
        ]
      },
      taskType: "RETRIEVAL_DOCUMENT",
      outputDimensionality: 768
    }

    {:ok, {{_, 200, _}, _h, response}} =
      :httpc.request(
        :post,
        {
          ~c"#{base_url()}/v1beta/models/gemini-embedding-001:embedContent",
          [
            {~c"x-goog-api-key", "#{api_key()}"},
            {~c"user-agent", "elixir client"}
          ],
          ~c"application/json",
          JSON.encode!(body)
        },
        [
          ssl: [
            verify: :verify_peer,
            cacerts: :public_key.cacerts_get(),
            # Support wildcard certificates
            customize_hostname_check: [
              match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
            ]
          ]
        ],
        []
      )

    response = response |> to_string() |> JSON.decode!()
    response["embedding"]["values"]
  end

  # One off for adding embedding to the packages.
  # We would only need to run this if we change the promopt
  # Or the data name, description or categories changes
  # We are not doing that for now, we keep it just in case we want
  # to regenerate the embeddings
  def run() do
    Toolbox.Packages.list_packages_names_with_no_embedding()
    |> Stream.chunk_every(3000)
    |> Stream.map(fn(names) ->
      names
      |> Toolbox.Packages.get_packages_by_name()
      |> Stream.chunk_every(100)
      |> Stream.map(fn(packages) -> calculate(packages) end)
      |> Stream.run()
    end)
    |> Stream.each(fn(_) -> Process.sleep(60000) end)
    |> Stream.run
  end


  def calculate(packages) do
    requests = for package <- packages do
      p = """
        #{package.name}

        #{package.description}

        #{package.category.name}
      """

      %{
        model: "models/gemini-embedding-001",
        content: %{
          parts: [
            %{
              text: p
            }
          ]
        },
        taskType: "RETRIEVAL_DOCUMENT",
        outputDimensionality: 768
      }
    end

  body = %{
    requests: requests
  }

  {:ok, {{_, 200, _}, _h, response}} =
    :httpc.request(
      :post,
      {
        ~c"#{base_url()}/v1beta/models/gemini-embedding-001:batchEmbedContents",
        [
          {~c"x-goog-api-key", "#{api_key()}"},
          {~c"user-agent", "elixir client"}
        ],
        ~c"application/json",
        JSON.encode!(body)
      },
      [
        ssl: [
          verify: :verify_peer,
          cacerts: :public_key.cacerts_get(),
          # Support wildcard certificates
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ]
        ]
      ],
      []
    )

    response = response |> to_string() |> JSON.decode!()
    embeddings = response["embeddings"]

    Enum.zip(packages, embeddings)
    |> Enum.each(fn {package, e} ->
      embedding = e["values"]
      Toolbox.Packages.upsert_package_embeddings(%{
        package_id: package.id,
        embedding: embedding
      })
    end)
  end

  def base_url() do
    Application.fetch_env!(:toolbox, :gemini_base_url)
  end

  def api_key() do
    Application.fetch_env!(:toolbox, :gemini_api_key)
  end
end
