defmodule Mix.Tasks.Packages do
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")
    Toolbox.Tasks.Packages.run()
  end
end
