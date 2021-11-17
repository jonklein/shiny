defmodule Shiny.Executor do
  require Logger

  def start_link(config) do
    Task.start_link(__MODULE__, :run, [config])
  end

  def run(config) do
    {strategy, state, symbols} = Shiny.Strategy.from_config(config)
    loop(config, symbols, state, %Shiny.Portfolio{}, strategy)
  end

  def loop(config, symbols, state, portfolio, strategy, last_timestamp \\ ~D[1900-01-01]) do
    bars =
      symbols
      |> Enum.reduce(%{}, fn symbol, acc ->
        Map.merge(acc, %{
          symbol => Enum.reverse(Shiny.Tradier.Quotes.request(symbol, config.timeframe, 2))
        })
      end)

    last =
      Map.values(bars)
      |> Enum.map(&List.first(&1).time)
      |> Enum.max()

    {state, portfolio} =
      if(last > last_timestamp) do
        # only execute strategy when quote_streamer new bars are received
        Logger.info("Executing strategy with bar closing #{last}")
        execute_strategy(state, strategy, portfolio, bars)
      else
        Logger.info("No new bars, skipping execution with bar closing (#{last})")
        {state, portfolio}
      end

    receive do
    after
      20_000 ->
        loop(config, symbols, state, portfolio, strategy, last)
    end
  end

  def execute_strategy(state, strategy, portfolio, quotes) do
    {state, trade} = strategy.execute(state, portfolio, quotes)

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
