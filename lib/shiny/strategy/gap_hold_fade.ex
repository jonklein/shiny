defmodule Shiny.Strategy.GapHoldFade do
  def execute(state, portfolio, bars) do
    current_bar = Enum.at(bars[state.symbol], 0)
    opening = opening_bars(state, bars[state.symbol])
    closing = closing_bars(state, bars[state.symbol])

    closing? = length(closing) > 1 && current_bar.time == hd(closing).time
    opening? = length(opening) > 1 && current_bar.time == hd(opening).time

    open = Enum.at(opening, 0)
    previous_close = Enum.at(closing, 1)

    shares = 10000 / current_bar.close

    cond do
      closing? && open.open > previous_close.close ->
        {
          state,
          %Shiny.Order{
            symbol: state.symbol,
            quantity: shares,
            type: :buy
          }
        }

      closing? && open.open < previous_close.close ->
        {
          state,
          %Shiny.Order{
            symbol: state.symbol,
            quantity: -shares,
            type: :buy
          }
        }

      opening? ->
        {
          state,
          %Shiny.Order{
            symbol: state.symbol,
            type: :close
          }
        }

      true ->
        {state, nil}
    end
  end

  def opening_bars(state, bars) do
    Enum.filter(bars, &(&1.time.hour == state.sell_hour && &1.time.minute == state.sell_minute))
  end

  def closing_bars(state, bars) do
    Enum.filter(bars, &(&1.time.hour == state.buy_hour && &1.time.minute == state.buy_minute))
  end
end
