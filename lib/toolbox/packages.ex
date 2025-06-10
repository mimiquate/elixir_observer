defmodule Toolbox.Packages do
  alias Toolbox.{GithubSnapshot, Github.GithubActivity, HexpmSnapshot, Package, Repo}

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

  def list_packages_names do
    from(p in Package, select: p.name)
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
        where: ilike(p.name, ^like_term),
        join: s in subquery(latest_hexpm_snaphost_query()),
        on: s.package_id == p.id,
        preload: [
          latest_hexpm_snapshot: ^latest_hexpm_snaphost_query(),
          latest_github_snapshot: ^latest_github_snaphost_query()
        ],
        order_by: [desc: json_extract_path(s.data, ["downloads", "recent"])],
        # TODO: Rework limit once we implement search result page pagination
        limit: ^limit + 1
      )
      |> Repo.all()
      |> Enum.split(limit)

    {exact_match, packages} = prioritize_exact_match(packages, term)

    {exact_match, packages, length(rest) > 0}
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

  def delete_github_snapshot(snapshot) do
    Repo.delete(snapshot)
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

  def get_github_activity(nil) do
    %GithubActivity{
      open_issue_count: "-",
      closed_issue_count: "-",
      open_pr_count: "-",
      merged_pr_count: "-",
      pull_requests: []
    }
  end

  @decorate cacheable(key: full_name, opts: [ttl: :timer.hours(24)])
  def get_github_activity(%{"full_name" => full_name}) do
    [owner, repo] = full_name |> String.split("/")

    with {:ok, {{_, 200, _}, _headers, data}} <-
           Toolbox.Github.get_activity_and_changelog(owner, repo),
         %{
           "data" => %{
             "repository" => %{
               "pullRequests" => %{
                 "nodes" => pull_requests
               }
             },
             "closedIssueCount" => %{"issueCount" => closed_issue_count},
             "mergedPRCount" => %{"issueCount" => merged_pr_count},
             "openIssueCount" => %{"issueCount" => open_issue_count},
             "openPRCount" => %{"issueCount" => open_pr_count}
           }
         } <- Jason.decode!(data) do
      year_ago = DateTime.utc_now() |> DateTime.shift(year: -1)

      pull_requests =
        pull_requests
        |> Enum.filter(fn p ->
          {:ok, p_created_at, _} = DateTime.from_iso8601(p["createdAt"])

          DateTime.diff(p_created_at, year_ago) > 0
        end)
        |> Enum.reverse()

      %GithubActivity{
        open_issue_count: open_issue_count,
        closed_issue_count: closed_issue_count,
        open_pr_count: open_pr_count,
        merged_pr_count: merged_pr_count,
        pull_requests: pull_requests
      }
    else
      err ->
        Logger.warning(%{
          name: "Unable to fetch github activity for #{full_name}",
          err: err
        })

        {:error, "Couldn't load recent activity data from GitHub"}
    end
  end

  # Private function to move exact matches to the top
  defp prioritize_exact_match(packages, term) do
    {exact_matches, other_matches} =
      Enum.split_with(packages, fn package ->
        String.downcase(package.name) == String.downcase(term)
      end)

    {Enum.at(exact_matches, 0), other_matches}
  end
end
