defmodule Shiny.Alpaca.Executor do
  require Logger

  def start_link(symbol, strategy) do
    Task.start_link(__MODULE__, :listen, [symbol, strategy])
  end

  def listen(symbol, strategy) do
    loop(symbol, strategy)
  end

  def loop(symbol, strategy) do
    Logger.info("Running at #{DateTime.utc_now()}")
    bars = Shiny.Alpaca.Quotes.request(symbol)
    last = Enum.at(bars, 0).time
    execute_strategy(strategy, bars)

    receive do
    after
      20_000 ->
        loop(symbol, strategy)
    end
  end

  def execute_strategy(strategy, quotes) do
    trade = strategy.execute(quotes)
  end
end
