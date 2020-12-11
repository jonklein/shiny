defmodule Shiny.Backtester do
  require Logger

  def backtest(symbol, strategy, days \\ 30) do
    portfolio = %Shiny.Portfolio{cash: 100_000}
    bars = Shiny.Alpaca.Quotes.request(symbol, days)

    execute_backtest(%{}, strategy, portfolio, symbol, bars, 1)
    |> Shiny.Portfolio.close(List.last(bars).time, symbol, List.last(bars).close)
  end

  def execute_backtest(_, _, portfolio, _, l, window) when length(l) <= window do
    portfolio
  end

  def execute_backtest(state, strategy, portfolio, symbol, bars, window) do
    {portfolio, state} =
      execute_strategy(state, strategy, portfolio, symbol, Enum.slice(bars, 0, window))

    execute_backtest(state, strategy, portfolio, symbol, bars, window + 1)
  end

  def execute_strategy(state, strategy, portfolio, symbol, quotes) do
    {state, order} = strategy.execute(state, portfolio, symbol, Enum.reverse(quotes))
    {process_trade(portfolio, quotes, order), state}
  end

  def process_trade(portfolio, _, nil) do
    portfolio
  end

  def process_trade(portfolio, quotes, trade = %Shiny.Order{}) do
    bar = List.last(quotes)
    Shiny.Portfolio.order(portfolio, %{trade | time: bar.time, limit: bar.close})
  end
end
