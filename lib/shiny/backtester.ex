defmodule Shiny.Backtester do
  require Logger

  def backtest(config) do
    {strategy, state, symbols} = Shiny.Strategy.from_config(config)

    bars =
      symbols
      |> Enum.reduce(%{}, fn symbol, acc ->
        Map.merge(acc, %{symbol => Shiny.Tradier.Quotes.request(symbol, config.timeframe, 30)})
      end)

    portfolio =
      %Shiny.Portfolio{}
      |> struct(config.portfolio)
      |> execute_backtest(strategy, state, bars, 1, nil)

    portfolio.positions
    |> Enum.reduce(portfolio, fn p, portfolio ->
      Shiny.Portfolio.close(
        portfolio,
        List.last(bars[p.symbol]).time,
        p.symbol,
        List.last(bars[p.symbol]).close
      )
    end)
  end

  def execute_backtest(portfolio, _, _, l, window, _) when length(l) <= window do
    portfolio
  end

  def execute_backtest(portfolio, strategy, state, bars, window, callback) do
    slicedbars =
      Enum.reduce(bars, %{}, fn {symbol, bars}, acc ->
        Map.merge(acc, %{symbol => Enum.reverse(Enum.slice(bars, 0, window))})
      end)

    {portfolio, state} = execute_strategy(portfolio, strategy, state, slicedbars)

    callback && callback.(portfolio, bars, state)

    sym = elem(Enum.at(bars, 0), 0)

    if length(bars[sym]) > window do
      execute_backtest(portfolio, strategy, state, bars, window + 1, callback)
    else
      portfolio
    end
  end

  def execute_strategy(portfolio, strategy, state, quotes) do
    {state, order} = strategy.execute(state, portfolio, quotes)
    {process_trade(portfolio, quotes, order), state}
  end

  defp process_trade(portfolio, _, nil) do
    portfolio
  end

  defp process_trade(portfolio, quotes, trade = %Shiny.Order{}) do
    bar = hd(quotes[trade.symbol])
    Shiny.Portfolio.order(portfolio, %{trade | time: bar.time, limit: trade.fill || bar.close})
  end
end
