defmodule Toolbox.Workers.HexpmWorker do
  use Oban.Worker, queue: :hexpm

  @impl Oban.Worker
  def perform(%Oban.Job{meta: %{"cron" => true}}) do
    Toolbox.Tasks.Hexpm.run()

    :ok
  end

  def perform(%Oban.Job{args: %{"action" => "get_package_owners", "name" => name}}) do
    {
      :ok,
      {
        {_, 200, _},
        _headers,
        owners_data
      }
    } = Toolbox.Hexpm.get_package_owners(name)

    owners_data = Phoenix.json_library().decode!(owners_data)

    Toolbox.Packages.get_package_by_name(name)
    |> Toolbox.Packages.update_package_owners(%{
      hexpm_owners_sync_at: DateTime.utc_now,
      hexpm_owners: owners_data
    })
    |> case do
      {:ok, p} ->
        Phoenix.PubSub.broadcast(
          Toolbox.PubSub,
          "package_live:#{name}",
          %{
            action: :refresh_owners,
            owners_sync_at: p.hexpm_owners_sync_at,
            owners: p.hexpm_owners
          }
        )
        {:ok, p}
      err -> err
    end
  end
end
