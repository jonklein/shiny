defmodule Shiny.Strategy.MacdCross do
  # A simple demo strategy using an MACD cross.  Probably not a good idea for live trading.

  def execute(portfolio, symbol, bars) do
    current_bar = hd(bars)
    closes = Enum.map(bars, & &1.close) |> Enum.slice(0, 100)

    macd_histogram = TAlib.Indicators.MACD.histogram(closes)
    position = Shiny.Portfolio.position(portfolio, symbol)

    if position do
      if(macd_histogram < 0) do
        %Shiny.Order{type: :close, symbol: symbol, limit: current_bar.close}
      end
    else
      if(macd_histogram > 0) do
        %Shiny.Order{type: :buy, symbol: symbol, shares: 100, limit: current_bar.close}
      end
    end
  end
end
