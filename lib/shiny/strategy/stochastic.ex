defmodule Shiny.Strategy.Stochastic do
  def execute(state, _, bars) do
    closing = bars[state.symbol] |> Enum.map(& &1.close)
    k = TAlib.Indicators.Stochastic.stochastic_k(closing)
    d = TAlib.Indicators.Stochastic.stochastic_d(closing)

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
