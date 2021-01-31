defmodule Shiny.Strategy.LRSI do
  import Shiny.Strategy.Utils

  def init(params) do
    Map.merge(params, %{bar_count: nil, stop: nil})
  end

  def manage(state, portolio, bars) do
    {state, nil}
  end

  def execute(state, portfolio, bars) when length(portfolio.positions) > 0 do
    [current | _] = bars[state.symbol]

    cond do
      length(bars[state.symbol]) >= state.bar_count + state.hold_bars ||
        current.close <= state.stop || current.close > state.stop + 15.0 ->
        {state,
         %Shiny.Order{
           symbol: state.symbol,
           type: :close,
           fill: max(current.close, state.stop)
         }}

      true ->
        {state, nil}
    end
  end

  def execute(state, portfolio, bars) do
    [current | _] = bars[state.symbol]
    closes = Enum.map(bars[state.symbol], & &1.close)

    lrsi2 = Breaker.Ta.lrsi(Enum.slice(Enum.map(bars[state.symbol], & &1.close), 1..20))

    vol =
      Enum.slice(bars[state.symbol], 0..2)
      |> Enum.map(&abs(&1.open - &1.close))
      |> Enum.sum()

    vol_threshold = Enum.at(bars[state.symbol], 0).open * 0.002

    cond do
      market_open?(current.time) && lrsi2 < state.threshold &&
        Enum.at(bars[state.symbol], 0).high > Enum.at(bars[state.symbol], 1).open + 0.1 &&
          vol > vol_threshold ->
        {%{
           state
           | bar_count: length(bars[state.symbol]),
             stop: Enum.at(bars[state.symbol], 0).open
         },
         %Shiny.Order{
           type: :target,
           symbol: state.symbol,
           shares: portfolio.cash / Enum.at(bars[state.symbol], 1).open,
           fill: Enum.at(bars[state.symbol], 1).open + 0.1
         }}

      true ->
        {state, nil}
    end
  end
end
