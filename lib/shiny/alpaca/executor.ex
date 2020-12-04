defmodule Shiny.Alpaca.Executor do
  require Logger

  def start_link(symbol, strategy) do
    Task.start_link(__MODULE__, :listen, [symbol, strategy])
  end

  def listen(symbol, strategy) do
    loop(%Shiny.Portfolio{}, symbol, strategy)
  end

  def backtest(symbol, strategy) do
    portfolio = %Shiny.Portfolio{cash: 100_000}
    bars = Shiny.Alpaca.Quotes.request(symbol, 40)

    execute_backtest(strategy, portfolio, symbol, bars, 1)
  end

  def execute_backtest(_, _, _, l, window) when length(l) <= window do
  end

  def execute_backtest(strategy, portfolio, symbol, bars, window) do
    portfolio = execute_strategy(strategy, portfolio, symbol, Enum.slice(bars, 0, window))
    execute_backtest(strategy, portfolio, symbol, bars, window + 1)
  end

  def loop(portfolio, symbol, strategy, last_timestamp \\ ~D[1900-01-01]) do
    Logger.info("Running at #{DateTime.utc_now()}")
    bars = Shiny.Alpaca.Quotes.request(symbol, 3)
    last = List.last(bars).time

    if(last > last_timestamp) do
      # only execture strategy when new bars are received
      IO.puts("Executing strategy with bar ending at #{last}")
      execute_strategy(strategy, portfolio, symbol, bars)
    else
      IO.puts("Skipping execution: #{last}, #{last_timestamp}")
    end

    receive do
    after
      20_000 ->
        loop(portfolio, symbol, strategy, last)
    end
  end

  def execute_strategy(strategy, portfolio, symbol, quotes) do
    process_trade(portfolio, strategy.execute(portfolio, symbol, Enum.reverse(quotes)))
  end

  def process_trade(portfolio, nil) do
    portfolio
  end

  def process_trade(portfolio, trade = %Shiny.Order{}) do
    Shiny.Portfolio.order(portfolio, trade) |> IO.inspect()
  end
end
