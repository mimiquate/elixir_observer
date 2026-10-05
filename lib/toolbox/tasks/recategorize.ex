defmodule Toolbox.Tasks.Recategorize do
  alias Toolbox.Packages
  alias Toolbox.Workers.RecategorizeWorker

  def run do
    Packages.list_packages_names()
    |> Enum.chunk_every(300)
    |> Enum.map(&RecategorizeWorker.new(%{names: &1}))
    |> Oban.insert_all()
  end
end
