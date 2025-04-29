defmodule Toolbox.Packages do
  alias Toolbox.{HexpmSnapshot, GithubSnapshot, Package, Repo}

  import Ecto.Query

  def list_packages do
    Repo.all(Package)
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
        # TODO: Remove limit once we implement search result pagination
        limit: ^limit + 1
      )
      |> Repo.all()
      |> Enum.split(limit)

    {packages, length(rest) > 0}
  end

  def get_package_by_name(name) do
    from(p in Package, where: p.name == ^name)
    |> Repo.one()
  end

  def get_package_by_name!(name) do
    from(p in Package, where: p.name == ^name)
    |> Repo.one!()
  end

  def last_hexpm_snapshot(pacakges) when is_list(pacakges) do
    package_ids = Enum.map(pacakges, & &1.id)

    ranking_query =
      from h in HexpmSnapshot,
        select: %{id: h.id, row_number: over(row_number(), :packages_partition)},
        windows: [packages_partition: [partition_by: :package_id, order_by: [desc: :id]]]

    from(h in HexpmSnapshot,
      where: h.package_id in ^package_ids,
      join: r in subquery(ranking_query),
      on: h.id == r.id and r.row_number == 1
    )
    |> Repo.all()
  end

  def last_hexpm_snapshot(package) do
    from(
      hs in HexpmSnapshot,
      where: hs.package_id == ^package.id,
      order_by: [desc: :id],
      limit: 1
    )
    |> Repo.one()
  end

  def last_github_snapshot(package) do
    from(
      hs in GithubSnapshot,
      where: hs.package_id == ^package.id,
      order_by: [desc: :id],
      limit: 1
    )
    |> Repo.one()
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
end
