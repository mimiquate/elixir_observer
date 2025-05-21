defmodule Toolbox.Workers.PackageFetcherWorker do
  use Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Toolbox.Tasks.Hexpm.run()
    Toolbox.Tasks.SCM.run()

    :ok
  end
end