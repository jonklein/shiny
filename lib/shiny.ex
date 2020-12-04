defmodule Shiny do
  def run() do
    Shiny.Executor.start_link("SPY", Shiny.Strategy.GapFade)
  end

  def backtest() do
    Shiny.Backtester.backtest("SPY", Shiny.Strategy.MacdCross, 30)
    |> Shiny.Portfolio.report()
  end
end
