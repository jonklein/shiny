defmodule Mix.Tasks.Backtest do
  use Mix.Task

  @shortdoc "Run a backtest"

  def run([config_file | rest]) do
    Mix.Task.run("app.start")

    runs =
      Shiny.Config.from_file!(config_file)
      |> run_config(rest)

    # Take list of keyword lists, extract into header & value rows
    rows = [Keyword.keys(Enum.at(runs, 0)) | Enum.map(runs, &Keyword.values(&1))]

    rows
    |> CSV.encode(headers: false)
    |> Enum.join("")
    |> IO.puts()
  end

  def run_config(config, [param | rest]) do
    [key_string, value] = String.split(param, "=")
    key = String.to_atom(key_string)

    Enum.reduce(String.split(value, ","), [], fn v, acc ->
      reports =
        run_config(Shiny.Config.put_param(config, key, v), rest)
        |> Enum.map(&Keyword.merge(&1, [{key, v}]))

      acc ++ reports
    end)
  end

  def run_config(config, []) do
    [
      config
      |> Shiny.Backtester.backtest()
      |> Shiny.Portfolio.report()
    ]
  end
end
