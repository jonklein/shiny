defmodule Mix.Tasks.Execute do
  use Mix.Task
  require Logger

  @shortdoc "Run a backtest"

  def run(argv) do
    Mix.Task.run("app.start")

    {config_file, params} = Mix.Tasks.Options.parse(argv)

    config = config(config_file, params)
    Logger.info(config)
    Shiny.Executor.run(config)
  end

  def config(config_file, [param | rest]) do
    [key_string, value] = String.split(param, "=")
    Shiny.Config.put_param(config(config_file, rest), String.to_atom(key_string), value)
  end

  def config(config_file, []) do
    Shiny.Config.from_file!(config_file)
  end
end
