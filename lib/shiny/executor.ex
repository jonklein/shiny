defmodule Shiny.Executor do
  require Logger

  def start_link(config) do
    Task.start_link(__MODULE__, :run, [config])
  end

  def run(config) do
    {strategy, state, symbols} = Shiny.Strategy.from_config(config)

    histories =
      Enum.reduce(symbols, %{}, fn sym, acc ->
        Map.merge(acc, %{
          sym => Shiny.Broker.module(config.data_broker, Quotes).request(sym, config.timeframe, 2)
        })
      end)

    Shiny.Broker.module(config.data_broker, QuoteStreamer).start_link(symbols, self())

    loop(config, histories, state, %Shiny.Portfolio{}, strategy)
  end

  def loop(config, histories, state, portfolio, strategy, last_timestamp \\ ~D[1900-01-01]) do
    {state, portfolio, last_timestamp} =
      receive do
        {:quotes, quotes} ->
          IO.inspect("received #{inspect(quotes)}")

          histories =
            Enum.reduce(quotes, histories, fn {sym, quote}, acc ->
              Map.merge(histories, %{sym => Shiny.Histories.add_quote(histories[sym], quote)})
            end)

          process(histories, state, portfolio, strategy, last_timestamp)
      after
        20_000 ->
          {state, portfolio, last_timestamp}
      end

    loop(config, histories, state, portfolio, strategy, last_timestamp)
  end

  defp process(histories, state, portfolio, strategy, last_timestamp) do
    bars =
      histories
      |> Enum.reduce(%{}, fn {sym, history}, acc -> Map.merge(acc, %{sym => history.bars}) end)

    last =
      Map.values(bars)
      |> Enum.map(&List.first(&1).time)
      |> Enum.max()

    {state, portfolio} =
      if(last > last_timestamp) do
        # only execute strategy when quote_streamer new bars are received
        Logger.info("Executing strategy with bar closing #{Calendar.strftime(last, "%c")}")
        execute_strategy(state, strategy, portfolio, bars)
      else
        Logger.debug(
          "No new bars, skipping execution with bar closing #{Calendar.strftime(last, "%c")}"
        )

        {state, portfolio}
      end

    {state, portfolio, last}
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
