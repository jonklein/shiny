defmodule Shiny.Strategy.Stochastic do
  defp performance(bars, period) do
    now = hd(bars)
    then = Enum.at(bars, period)

    if now && then do
      100 * (1.0 - now.close / then.close)
    else
      0.0
    end
  end

  def execute(state, portfolio, bars) do
    closing = bars[state.symbol] |> Enum.map(& &1.close)
    k = TAlib.Indicators.Stochastic.stochastic_k(closing)
    d = TAlib.Indicators.Stochastic.stochastic_d(closing)

    ph = performance(bars, 12)
    pd = performance(bars, 12 * 24)
    pdd = performance(bars, 12 * 24 * 12)

    shares = 10000 / 400

    cond do
      k - d > 3 && d <= 10 && Shiny.Strategy.Utils.market_open?(hd(bars[state.symbol]).time) ->
        {
          state,
          %Shiny.Order{
            symbol: state.symbol,
            quantity: shares,
            type: :target
          }
        }

      d - k > 5 ->
        {
          state,
          %Shiny.Order{
            symbol: state.symbol,
            quantity: 0,
            type: :target
          }
        }

      true ->
        {
          state,
          nil
        }
    end
  end

  def opening_bars(state, bars) do
    Enum.filter(bars, &(&1.time.hour == state.sell_hour && &1.time.minute == state.sell_minute))
  end

  def closing_bars(state, bars) do
    Enum.filter(bars, &(&1.time.hour == state.buy_hour && &1.time.minute == state.buy_minute))
  end
end
