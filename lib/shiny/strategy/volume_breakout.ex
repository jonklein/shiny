defmodule Shiny.Strategy.VolumeBreakout do
  @scale 1.2

  def params() do
    %{
      symbols: ["SPY"],
      timeframe: "day",
      portfolio_value: 100_000
    }
  end

  def execute(state, portfolio, symbol, bars) do
    [first | rest] = bars

    #    macd_histogram = TAlib.Indicators.MACD.histogram(closes)
    position = Shiny.Portfolio.position(portfolio, symbol)

    cond do
      !position && inside_bars(first, rest) > 5 ->
        {state, %Shiny.Order{type: :buy, shares: 100, symbol: symbol}}

      position && first.close > position.cost_basis * 1.03 ->
        {state, %Shiny.Order{type: :close, symbol: symbol}}

      position && first.close < position.cost_basis * 0.99 ->
        {state, %Shiny.Order{type: :close, symbol: symbol}}

      true ->
        {state, nil}
    end
  end

  def inside_bars(_, []) do
    0
  end

  def inside_bars(reference, [first | rest]) do
    cond do
      first.volume < reference.volume * @scale -> 1 + inside_bars(reference, rest)
      true -> 0
    end
  end
end
