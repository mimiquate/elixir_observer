defmodule Toolbox.Packages do
  alias Toolbox.{GithubSnapshot, HexpmSnapshot, Package, Repo, Category}

  require Logger

  import Ecto.Query

  use Nebulex.Caching, cache: Toolbox.Cache

  def list_packages do
    from(
      p in Package,
      preload: [
        latest_hexpm_snapshot: ^latest_hexpm_snaphost_query(),
        latest_github_snapshot: ^latest_github_snaphost_query()
      ]
    )
    |> Repo.all()
  end

  def list_categories do
    Category.all()
  end

  def list_packages_names do
    from(p in Package, select: p.name)
    |> Repo.all()
  end

  def list_packages_names_with_no_category do
    categories = Category.all()

    from(p in Package,
      where: is_nil(p.category) or p.category not in ^categories,
      join: s in subquery(latest_hexpm_snaphost_query()),
      on: s.package_id == p.id,
      select: p.name,
      order_by: [desc: json_extract_path(s.data, ["downloads", "recent"])]
    )
    |> Repo.all()
  end

  def list_packages_from_category(category, limit \\ nil)

  def list_packages_from_category(nil, _) do
    []
  end

  def list_packages_from_category(category, limit) do
    query =
      from(
        p in Package,
        where: p.category == ^category,
        join: s in subquery(latest_hexpm_snaphost_query()),
        on: s.package_id == p.id,
        preload: [
          latest_hexpm_snapshot: ^latest_hexpm_snaphost_query(),
          latest_github_snapshot: ^latest_github_snaphost_query()
        ],
        order_by: [desc: json_extract_path(s.data, ["downloads", "recent"])]
      )

    query =
      if limit do
        query |> Ecto.Query.limit(^limit)
      else
        query
      end

    Repo.all(query)
  end

  def total_count do
    Repo.aggregate(Package, :count)
  end

  def categories_counts do
    from(p in Package,
      where: not is_nil(p.category),
      group_by: p.category,
      select: {p.category, count(p.id)}
    )
    |> Repo.all()
    |> Map.new()
  end

  def category_count(category) do
    from(p in Package, where: p.category == ^category)
    |> Repo.aggregate(:count)
  end

  def search(term) do
    limit = 50
    like_term = "%#{term}%"
    downcase_term = String.downcase(term)

    {packages, rest} =
      from(
        p in Package,
        where: ilike(p.name, ^like_term),
        join: s in subquery(latest_hexpm_snaphost_query()),
        on: s.package_id == p.id,
        preload: [
          latest_hexpm_snapshot: ^latest_hexpm_snaphost_query(),
          latest_github_snapshot: ^latest_github_snaphost_query()
        ],
        order_by: [
          asc: fragment("CASE WHEN LOWER(?) = ? THEN 0 ELSE 1 END", p.name, ^downcase_term),
          desc_nulls_last: json_extract_path(s.data, ["downloads", "recent"])
        ],
        # TODO: Rework limit once we implement search result page pagination
        limit: ^limit + 1
      )
      |> Repo.all()
      |> Enum.split(limit)

    {packages, length(rest) > 0}
  end

  def get_package_by_name(name) do
    from(p in Package,
      where: p.name == ^name,
      preload: [
        latest_hexpm_snapshot: ^latest_hexpm_snaphost_query(),
        latest_github_snapshot: ^latest_github_snaphost_query()
      ]
    )
    |> Repo.one()
  end

  def get_package_by_name!(name) do
    from(p in Package,
      where: p.name == ^name,
      preload: [
        latest_hexpm_snapshot: ^latest_hexpm_snaphost_query(),
        latest_github_snapshot: ^latest_github_snaphost_query()
      ]
    )
    |> Repo.one!()
  end

  def get_packages_by_name(names) do
    from(p in Package, where: p.name in ^names)
    |> Repo.all()
  end

  def get_category_by_id!(id) do
    Category.all()
    |> Enum.find(fn c -> c.id == id end)
    |> case do
      nil -> raise Ecto.NoResultsError, queryable: Category
      c -> c
    end
  end

  def get_category_by_permalink!(permalink) do
    Category.all()
    |> Enum.find(fn c -> c.permalink == permalink end)
    |> case do
      nil -> raise Ecto.NoResultsError, queryable: Category
      c -> c
    end
  end

  def create_package(attributes \\ %{}) do
    %Package{}
    |> Package.changeset(attributes)
    |> Repo.insert()
  end

  def update_package_owners(package, attributes \\ %{}) do
    package
    |> Package.owners_changeset(attributes)
    |> Repo.update()
  end

  def update_package_category(package, attributes \\ %{}) do
    package
    |> Package.category_changeset(attributes)
    |> Repo.update()
  end

  def update_package_latest_stable_version(package, attributes \\ %{}) do
    package
    |> Package.latest_stable_version_data_changeset(attributes)
    |> Repo.update()
  end

  def create_hexpm_snapshot(attributes \\ %{}) do
    %HexpmSnapshot{}
    |> HexpmSnapshot.changeset(attributes)
    |> Repo.insert()
  end

  def upsert_github_snapshot(attributes \\ %{}) do
    from(s in GithubSnapshot,
      where: s.package_id == ^attributes.package_id,
      order_by: [desc: :id],
      limit: 1
    )
    |> Repo.one()
    |> case do
      nil -> %GithubSnapshot{}
      s -> s
    end
    |> GithubSnapshot.changeset(attributes)
    |> Repo.insert_or_update()
  end

  defp latest_hexpm_snaphost_query() do
    ranking_query =
      from h in HexpmSnapshot,
        select: %{id: h.id, row_number: over(row_number(), :packages_partition)},
        windows: [packages_partition: [partition_by: :package_id, order_by: [desc: :id]]]

    from h in HexpmSnapshot,
      join: r in subquery(ranking_query),
      on: h.id == r.id and r.row_number == 1
  end

  def delete_github_snapshots(%Package{id: id}) do
    GithubSnapshot
    |> where([gs], gs.package_id == ^id)
    |> Repo.delete_all()
  end

  defp latest_github_snaphost_query() do
    ranking_query =
      from g in GithubSnapshot,
        select: %{id: g.id, row_number: over(row_number(), :packages_partition)},
        windows: [packages_partition: [partition_by: :package_id, order_by: [desc: :id]]]

    from g in GithubSnapshot,
      join: r in subquery(ranking_query),
      on: g.id == r.id and r.row_number == 1
  end
end
