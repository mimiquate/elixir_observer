defmodule Mix.Tasks.Toolbox.Scm do
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")
    Toolbox.Tasks.SCM.run(args)
  end
end
