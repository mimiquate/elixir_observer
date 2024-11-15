defmodule Mix.Tasks.Packages do
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")
    ElixirToolbox.Tasks.Packages.run()
  end
end
