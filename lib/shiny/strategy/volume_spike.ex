defmodule Shiny.Strategy.VolumeSpike do
  import Shiny.Strategy.Utils

  def init(params) do
    Map.merge(params, %{stop: nil, target: nil})
  end

  #  defp lower_closes([d1, d2 | rest]) do
  #    if d1.close < d2.close do
  #      1 + lower_closes([d2 | rest])
  #    else
  #      0
  #    end
  #  end
  #
  #  defp lower_closes(_) do
  #    0
  #  end

  defp higher_closes([d1, d2 | rest]) do
    if d1.close > d2.close do
      1 + higher_closes([d2 | rest])
    else
      0
    end
  end

  defp higher_closes(_) do
    0
  end

  def manage(state, _, _) do
    {state, nil}
  end

  def mid(bar) do
    (bar.bid + bar.ask) / 2
  end

  def execute(state, portfolio, bars) when length(portfolio.positions) > 0 do
    [current | _] = bars[state.symbol]

    cond do
      current.close <= state.stop ->
        {state,
         %Shiny.Order{
           symbol: state.symbol,
           # fill: state.stop,
           type: :close
         }}

      current.close >= state.target ->
        {state,
         %Shiny.Order{
           #           fill: state.target,
           symbol: state.symbol,
           type: :close
         }}

      true ->
        {%{
           state
           | stop: max(state.stop, current.close * (1.0 - state.stop_loss_percent / 100.0))
         }, nil}
    end
  end

  def execute(state, _, bars) do
    [current | rest] = bars[state.symbol]
    previous = Enum.at(rest, 0)

    closes = Enum.map(Map.get(bars, state.symbol), & &1.close) |> Enum.slice(0, 100)
    histo1 = TAlib.Indicators.MACD.histogram(closes)
    histo2 = TAlib.Indicators.MACD.histogram(closes, 20, 40)

    if market_open?(current.time) && higher_closes(rest) > state.close_count &&
         histo1 * histo2 > 0 &&
         current.close < previous.close && current.close > previous.open && abs(histo1) > 0.0 do
      shares = ceil(10000 / current.close)

      {%{
         state
         | stop: current.close * (1.0 - state.target_percent / 100.0),
           target: current.close * (1.0 + state.target_percent / 100.0)
       },
       %Shiny.Order{
         symbol: state.symbol,
         quantity: (histo1 > 0.0 && shares) || -shares,
         type: :target
       }}
    else
      {state, nil}
    end
  end
end
