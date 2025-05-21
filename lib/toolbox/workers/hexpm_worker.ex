defmodule Toolbox.Workers.HexpmWorker do
  use Oban.Worker, queue: :hexpm

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Toolbox.Tasks.Hexpm.run()

    :ok
  end
end
