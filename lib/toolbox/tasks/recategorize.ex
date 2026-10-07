defmodule Toolbox.Tasks.Recategorize do
  alias Toolbox.Packages
  alias Toolbox.Workers.RecategorizeWorker

  def run do
    Packages.list_packages_names()
    |> Enum.map(&RecategorizeWorker.new(%{name: &1}))
    |> Enum.chunk_every(500)
    |> Enum.each(&Oban.insert_all/1)
  end
end
