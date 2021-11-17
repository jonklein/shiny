defmodule Mix.Tasks.Backtest do
  use Mix.Task
  require Logger

  @shortdoc "Run a backtest"

  def run(argv) do
    Mix.Task.run("app.start")

    {config_file, params} = Mix.Tasks.Options.parse(argv)

    runs =
      Shiny.Config.from_file!(config_file)
      |> run_config(params)

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
    Logger.info(config)

    [
      config
      |> Shiny.Backtester.backtest()
      |> Shiny.Portfolio.report()
    ]
  end
end
