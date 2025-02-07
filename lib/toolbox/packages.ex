defmodule Toolbox.Packages do
  alias Toolbox.{HexpmSnapshot, GithubSnapshot, Package, Repo}

  import Ecto.Query

  def list_packages do
    Repo.all(Package)
  end

  def get_package_by_name(name) do
    from(p in Package, where: p.name == ^name)
    |> Repo.one()
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
