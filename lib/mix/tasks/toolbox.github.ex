defmodule Mix.Tasks.Toolbox.Github do
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")
    Toolbox.Tasks.Github.run()
  end
end
