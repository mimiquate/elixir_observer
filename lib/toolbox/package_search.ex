defmodule Toolbox.PackageSearch do
  @moduledoc """
  Handles package search functionality with filter parsing and validation.

  This module is responsible for:
  - Parsing search filters (e.g., "type:semantic")
  - Validating search queries
  - Routing to appropriate search implementations
  - Providing a clean API for package search operations
  """

  alias Toolbox.{Package, Repo, PackageEmbedding, HexpmSnapshot}

  import Ecto.Query
  import Pgvector.Ecto.Query

  use Nebulex.Caching, cache: Toolbox.Cache

  @filter_regex ~r/(?<type>\w+):(?<value>\w+)/
  @min_search_length 3

  defstruct [:original_term, :filters, :clean_term]

  @doc """
  Parses a search term into a PackageSearch struct.

  ## Examples

      iex> PackageSearch.parse("phoenix type:semantic")
      %PackageSearch{
        original_term: "phoenix type:semantic",
        filters: %{"type" => "semantic"},
        clean_term: "phoenix"
      }
  """
  def parse(term) do
    filters = parse_filters(term)
    clean_term = clean_search_term(term)

    %__MODULE__{
      original_term: term,
      filters: filters,
      clean_term: clean_term
    }
  end

  @doc """
  Checks if a parsed search can be executed.

  A search can be executed if:
  - The clean term has at least #{@min_search_length} characters

  ## Examples

      iex> search = PackageSearch.parse("phoenix")
      iex> PackageSearch.executable?(search)
      true

      iex> search = PackageSearch.parse("type:semantic")
      iex> PackageSearch.executable?(search)
      false

      iex> search = PackageSearch.parse("ph")
      iex> PackageSearch.executable?(search)
      false
  """
  def executable?(%__MODULE__{clean_term: clean_term}) do
    String.length(clean_term) >= @min_search_length
  end

  @doc """
  Executes a search using a parsed PackageSearch struct.

  Returns a tuple with packages and a boolean indicating if there are more results.

  ## Examples

      iex> search = PackageSearch.parse("phoenix")
      iex> {packages, has_more?} = PackageSearch.execute(search)
      {[...], false}
  """
  def execute(%__MODULE__{} = parsed_search) do
    if semantic?(parsed_search) do
      embedding_search(parsed_search.clean_term)
    else
      keyword_search(parsed_search.clean_term)
    end
  end

  # Private functions

  defp parse_filters(full_term) do
    Regex.scan(@filter_regex, full_term)
    |> Enum.map(fn [_full, key, value] -> %{key => value} end)
    |> Enum.reduce(%{}, &Map.merge/2)
  end

  defp clean_search_term(full_term) do
    String.replace(full_term, @filter_regex, "")
    |> String.trim()
    |> String.replace(~r/\s+/, " ")
  end

  defp semantic?(%__MODULE__{filters: filters}) do
    filters["type"] == "semantic"
  end

  defp embedding_search(term) do
    limit = 50
    downcase_term = String.downcase(term)
    vector = embedding_from_term(term)

    {packages, rest} =
      from(p in Package,
        join: e in PackageEmbedding,
        on: e.package_id == p.id,
        join: s in subquery(latest_hexpm_snaphost_query()),
        on: s.package_id == p.id,
        where: l2_distance(e.embedding, ^vector) < 0.4,
        preload: [
          latest_hexpm_snapshot: ^latest_hexpm_snaphost_query(),
          latest_github_snapshot: ^latest_github_snaphost_query()
        ],
        order_by: [
          asc: fragment("CASE WHEN LOWER(?) = ? THEN 0 ELSE 1 END", p.name, ^downcase_term),
          desc_nulls_last: s.recent_downloads
        ],
        limit: ^limit + 1
      )
      |> Repo.all()
      |> Enum.split(limit)

    {packages, length(rest) > 0}
  end

  defp keyword_search(term) do
    limit = 50
    like_term = "%#{term}%"
    downcase_term = String.downcase(term)

    {packages, rest} =
      from(
        p in Package,
        where: ilike(p.name, ^like_term) or ilike(p.description, ^like_term),
        join: s in subquery(latest_hexpm_snaphost_query()),
        on: s.package_id == p.id,
        preload: [
          latest_hexpm_snapshot: ^latest_hexpm_snaphost_query(),
          latest_github_snapshot: ^latest_github_snaphost_query()
        ],
        order_by: [
          asc: fragment("CASE WHEN LOWER(?) = ? THEN 0 ELSE 1 END", p.name, ^downcase_term),
          desc_nulls_last: s.recent_downloads
        ],
        limit: ^limit + 1
      )
      |> Repo.all()
      |> Enum.split(limit)

    {packages, length(rest) > 0}
  end

  @decorate cacheable(key: {:embedding, term}, opts: [ttl: :timer.hours(240)])
  def embedding_from_term(term) do
    term
    |> Toolbox.Tasks.Embedding.calculate_query()
    |> Pgvector.new()
  end


  defp latest_hexpm_snaphost_query do
    from(h in HexpmSnapshot.Latest)
  end

  defp latest_github_snaphost_query do
    from(g in Toolbox.GithubSnapshot)
  end
end
