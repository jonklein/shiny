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

    {state, portfolio} =
      if(last > last_timestamp) do
        # only execture strategy when new bars are received
        IO.puts("Executing strategy with bar ending at #{last}")
        execute_strategy(state, strategy, portfolio, bars)
      else
        IO.puts("Skipping execution: #{last}, #{last_timestamp}")
        {state, portfolio}
      end

    receive do
    after
      20_000 ->
        loop(state, portfolio, symbol, strategy, last)
    end
  end

  def execute_strategy(state, strategy, portfolio, quotes) do
    {state, trade} = strategy.execute(state, portfolio, Enum.reverse(quotes))

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

  def process_trade(portfolio, quotes, order = %Shiny.Order{symbol: symbol}) do
    order |> IO.inspect()
    Shiny.Portfolio.order(portfolio, %{order | time: List.last(quotes[symbol]).time})
  end
end
