defmodule Mix.Tasks.Toolbox.Hexpm do
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")
    Toolbox.Tasks.Hexpm.run()
  end
end
