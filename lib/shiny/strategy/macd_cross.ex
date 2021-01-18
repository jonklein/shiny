defmodule Shiny.Strategy.MacdCross do
  # A simple demo strategy using an MACD cross.  Probably not a good idea for live trading.

  def init([symbol]) do
    %{symbol: symbol, last_histo: 0, stop: 0.0}
  end

  def params([symbol]) do
    %{
      symbols: [symbol],
      timeframe: "day",
      portfolio_value: 100_000
    }
  end

  def execute(state, _portfolio, bars) do
    closes = Enum.map(Map.get(bars, state.symbol), & &1.close) |> Enum.slice(0, 100)

    histo = TAlib.Indicators.MACD.histogram(closes)

    cond do
      hd(closes) < state.stop ->
        {%{state | last_histo: histo, stop: 0.0},
         %Shiny.Order{type: :close, symbol: state.symbol}}

      histo < state.last_histo ->
        {%{state | last_histo: histo, stop: hd(closes) - 0.1},
         %Shiny.Order{type: :target, symbol: state.symbol, shares: 100}}

      true ->
        {%{state | last_histo: histo, stop: max(state.stop, hd(closes) - 0.1)}, nil}
    end
  end
end
