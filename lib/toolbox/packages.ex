defmodule Toolbox.Packages do
  alias Toolbox.{
    GithubSnapshot,
    HexpmSnapshot,
    Package,
    Repo,
    Category,
    PackageEmbedding
  }

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

  def list_packages_names_with_no_embedding do
    from(p in Package,
      left_join: e in PackageEmbedding,
      on: p.id == e.package_id,
      where: is_nil(e.package_id),
      select: p.name
    )
    |> Repo.all()
  end

  def list_packages_names_with_no_category do
    categories = Category.all()

    from(p in Package,
      where: is_nil(p.category) or p.category not in ^categories,
      join: s in subquery(latest_hexpm_snaphost_query()),
      on: s.package_id == p.id,
      select: p.name,
      order_by: [desc_nulls_last: s.recent_downloads]
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
        where: p.id in ^top_3000_packages_ids(),
        where: p.category == ^category,
        join: s in subquery(latest_hexpm_snaphost_query()),
        on: s.package_id == p.id,
        preload: [
          latest_hexpm_snapshot: ^latest_hexpm_snaphost_query(),
          latest_github_snapshot: ^latest_github_snaphost_query()
        ],
        order_by: [desc_nulls_last: s.recent_downloads]
      )

    query =
      if limit do
        query |> Ecto.Query.limit(^limit)
      else
        query
      end

    query
    |> Repo.all()
  end

  def list_packages_from_user(user_id) do
    from(p in Package,
      join: up in Toolbox.UserPackage,
      on: up.package_id == p.id,
      where: up.user_id == ^user_id and up.following == true,
      preload: [
        latest_hexpm_snapshot: ^latest_hexpm_snaphost_query(),
        latest_github_snapshot: ^latest_github_snaphost_query()
      ],
      order_by: [desc: up.inserted_at]
    )
    |> Repo.all()
  end

  # Categories count based on the top 3000 packages
  def categories_counts do
    from(p in Package,
      where: p.id in ^top_3000_packages_ids(),
      group_by: p.category,
      select: {p.category, count(p.id)}
    )
    |> Repo.all()
    |> Map.new()
  end

  def category_count(nil), do: 0

  def category_count(category) do
    from(p in Package,
      where: p.id in ^top_3000_packages_ids(),
      where: p.category == ^category
    )
    |> Repo.aggregate(:count)
  end

  ### XXX Remove this when adding recent downloads to package
  @decorate cacheable(key: :top_3000_packages_ids, opts: [ttl: :timer.hours(24)])
  def top_3000_packages_ids() do
    from(p in Package,
      join: s in subquery(latest_hexpm_snaphost_query()),
      on: s.package_id == p.id,
      order_by: [desc_nulls_last: s.recent_downloads],
      limit: 3000,
      select: p.id
    )
    |> Repo.all()
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

  def upsert_package_embeddings(attributes \\ %{}) do
    from(s in PackageEmbedding,
      where: s.package_id == ^attributes.package_id
    )
    |> Repo.one()
    |> case do
      nil -> %PackageEmbedding{}
      s -> s
    end
    |> PackageEmbedding.changeset(attributes)
    |> Repo.insert_or_update()
  end

  def refresh_latest_hexpm_snapshots() do
    Ecto.Adapters.SQL.query!(
      Repo,
      "REFRESH MATERIALIZED VIEW CONCURRENTLY latest_hexpm_snapshots;",
      [],
      timeout: 600_000
    )
  end

  def skip_refresh_latest_hexpm_snapshots() do
    Ecto.Adapters.SQL.query!(
      Repo,
      "SET LOCAL toolbox.skip_refresh_latest_hexpm_snapshots = 'on'"
    )
  end

  defp latest_hexpm_snaphost_query() do
    from(h in HexpmSnapshot.Latest)
  end

  def delete_github_snapshots(%Package{id: id}) do
    GithubSnapshot
    |> where([gs], gs.package_id == ^id)
    |> Repo.delete_all()
  end

  defdelegate community_resources_for(package),
    to: Toolbox.CommunityResources,
    as: :find_by_package

  defp latest_github_snaphost_query() do
    from(g in GithubSnapshot)
  end
end
