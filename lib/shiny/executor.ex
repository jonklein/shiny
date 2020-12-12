defmodule Shiny.Executor do
  require Logger

  def start_link(symbol, strategy) do
    Task.start_link(__MODULE__, :listen, [symbol, strategy])
  end

  def listen(symbol, strategy) do
    loop(%{}, %Shiny.Portfolio{}, symbol, strategy)
  end

  def loop(state, portfolio, symbol, strategy, last_timestamp \\ ~D[1900-01-01]) do
    Logger.info("Running at #{DateTime.utc_now()}")
    bars = Shiny.Alpaca.Quotes.request(symbol, 3)
    last = List.last(bars).time

    if(last > last_timestamp) do
      # only execture strategy when new bars are received
      IO.puts("Executing strategy with bar ending at #{last}")
      {state, portfolio} = execute_strategy(state, strategy, portfolio, symbol, bars)
    else
      IO.puts("Skipping execution: #{last}, #{last_timestamp}")
    end

    receive do
    after
      20_000 ->
        loop(state, portfolio, symbol, strategy, last)
    end
  end

  def execute_strategy(state, strategy, portfolio, symbol, quotes) do
    {state, trade} = strategy.execute(state, portfolio, symbol, Enum.reverse(quotes))

    portfolio =
      process_trade(
        portfolio,
        quotes,
        trade
      )

    {state, portfolio}
  end

  def process_trade(portfolio, _, nil) do
    portfolio
  end

  def process_trade(portfolio, quotes, trade = %Shiny.Order{}) do
    Shiny.Portfolio.order(portfolio, %{trade | time: List.last(quotes).time})
  end
end
