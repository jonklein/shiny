defmodule Shiny.Strategy.MacdCross do
  # A simple demo strategy using an MACD cross.  Probably not a good idea for live trading.

  def execute(state, portfolio, symbol, bars) do
    current_bar = hd(bars)
    closes = Enum.map(bars, & &1.close) |> Enum.slice(0, 100)

    macd_histogram = TAlib.Indicators.MACD.histogram(closes)
    position = Shiny.Portfolio.position(portfolio, symbol)

    cond do
      position && macd_histogram < 0 ->
        {state, %Shiny.Order{type: :close, symbol: symbol}}

      !position && macd_histogram > 0 ->
        {state, %Shiny.Order{type: :buy, symbol: symbol, shares: 100}}

      true ->
        {state, nil}
    end
  end
end
