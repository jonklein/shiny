defmodule Shiny.Strategy.LRSI do
  def init(params) do
    Map.merge(params, %{bar_count: nil, stop: nil})
  end

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

  defp market_open?(date) do
    t = DateTime.to_time(date)

    Time.compare(t, ~T[09:30:00]) == :gt && Time.compare(t, ~T[16:00:00]) == :lt
  end

  def manage(state, portolio, bars) do
    {state, nil}
  end

  def mid(bar) do
    (bar.bid + bar.ask) / 2
  end

  def execute(state, portfolio, bars) when length(portfolio.positions) > 0 do
    [current | _] = bars[state.symbol]
    closes = Enum.map(bars[state.symbol], & &1.close)

    lrsi1 = Breaker.Ta.lrsi(Enum.slice(closes, 0..20))
    lrsi2 = Breaker.Ta.lrsi(Enum.slice(closes, 1..20))

    cond do
      length(bars[state.symbol]) >= state.bar_count + state.hold_bars ||
          current.close <= state.stop ->
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
    opens = Enum.map(bars[state.symbol], & &1.open)

    lrsi1 = Breaker.Ta.lrsi(Enum.slice(closes, 0..20))
    lrsi2 = Breaker.Ta.lrsi(Enum.slice(closes, 1..20))
    lrsi3 = Breaker.Ta.lrsi(Enum.slice(closes, 2..20))

    vol =
      Enum.slice(bars[state.symbol], 0..2)
      |> Enum.map(&abs(&1.open - &1.close))
      |> Enum.sum()

    cond do
      market_open?(current.time) && lrsi2 < state.threshold &&
        Enum.at(bars[state.symbol], 0).high > Enum.at(bars[state.symbol], 1).open + 0.1 &&
          vol > 0.6 ->
        {%{
           state
           | bar_count: length(bars[state.symbol]),
             stop: Enum.at(bars[state.symbol], 0).open
         },
         %Shiny.Order{
           type: :target,
           symbol: state.symbol,
           shares: 50,
           fill: Enum.at(bars[state.symbol], 1).open + 0.1
         }}

      #      market_open?(current.time) && lrsi1 < 1.0 - state.threshold && lrsi2 > 1.0 - state.threshold &&
      #          vol > 0.7 ->
      #        {%{state | bar_count: length(bars[state.symbol])},
      #         %Shiny.Order{
      #           type: :target,
      #           symbol: state.symbol,
      #           shares: (histo > 0 && 50) || -50
      #         }}

      true ->
        {state, nil}
    end
  end
end
