defmodule Mix.Tasks.Execute do
  use Mix.Task

  @shortdoc "Run a backtest"

  def run([config_file | params]) do
    Mix.Task.run("app.start")

    Shiny.Executor.run(config(config_file, params) |> IO.inspect())
  end

  def config(config_file, [param | rest]) do
    [key_string, value] = String.split(param, "=")
    Shiny.Config.put_param(config(config_file, rest), String.to_atom(key_string), value)
  end

  def config(config_file, []) do
    Shiny.Config.from_file!(config_file)
  end
end
