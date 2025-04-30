defmodule Toolbox.Packages do
  alias Toolbox.{HexpmSnapshot, GithubSnapshot, Package, Repo}

  import Ecto.Query

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

  def total_count do
    Repo.aggregate(Package, :count)
  end

  def search(term) do
    limit = 50
    like_term = "%#{term}%"

    {packages, rest} =
      from(
        p in Package,
        where: like(p.name, ^like_term),
        join: s in subquery(latest_hexpm_snaphost_query()),
        on: s.package_id == p.id,
        preload: [
          latest_hexpm_snapshot: ^latest_hexpm_snaphost_query(),
          latest_github_snapshot: ^latest_github_snaphost_query()
        ],
        order_by: [desc: json_extract_path(s.data, ["downloads", "recent"])],
        # TODO: Remove limit once we implement search result pagination
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

  def create_package(attributes \\ %{}) do
    %Package{}
    |> Package.changeset(attributes)
    |> Repo.insert()
  end

  def create_hexpm_snapshot(attributes \\ %{}) do
    %HexpmSnapshot{}
    |> HexpmSnapshot.changeset(attributes)
    |> Repo.insert()
  end

  def create_github_snapshot(attributes \\ %{}) do
    %GithubSnapshot{}
    |> GithubSnapshot.changeset(attributes)
    |> Repo.insert()
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
