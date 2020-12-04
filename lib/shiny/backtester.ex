defmodule Shiny.Backtester do
  require Logger

  def backtest(symbol, strategy, days \\ 30) do
    portfolio = %Shiny.Portfolio{cash: 100_000}
    bars = Shiny.Alpaca.Quotes.request(symbol, days)

    execute_backtest(strategy, portfolio, symbol, bars, 1)
    |> Shiny.Portfolio.close(List.last(bars).time, symbol, List.last(bars).close)
  end

  def execute_backtest(_, portfolio, _, l, window) when length(l) <= window do
    portfolio
  end

  def execute_backtest(strategy, portfolio, symbol, bars, window) do
    portfolio = execute_strategy(strategy, portfolio, symbol, Enum.slice(bars, 0, window))
    execute_backtest(strategy, portfolio, symbol, bars, window + 1)
  end

  def execute_strategy(strategy, portfolio, symbol, quotes) do
    process_trade(portfolio, quotes, strategy.execute(portfolio, symbol, Enum.reverse(quotes)))
  end

  def process_trade(portfolio, _, nil) do
    portfolio
  end

  def process_trade(portfolio, quotes, trade = %Shiny.Order{}) do
    Shiny.Portfolio.order(portfolio, %{trade | time: List.last(quotes).time})
  end
end
