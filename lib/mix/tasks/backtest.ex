defmodule Mix.Tasks.Backtest do
  use Mix.Task

  @shortdoc "Run a backtest"

  def run([strategy]) do
    run(["SPY", strategy])
  end

  def run([symbol, strategy]) do
    run(["SPY", strategy, "30"])
  end

  def run([symbol, strategy, day_string]) do
    {days, _} = Integer.parse(day_string)
    Application.ensure_all_started(:hackney)
    Application.ensure_all_started(:httpoison)
    Application.ensure_all_started(:tzdata)

    Shiny.Backtester.backtest(symbol, resolve_strategy(strategy), days)
    |> Shiny.Portfolio.report()
  end

  def resolve_strategy(strategy) do
    {module, _} = Code.eval_string(strategy)
    module
  end
end
