defmodule Shiny.Strategy.GapFade do
  @first_bar_hour 9
  @first_bar_minute 30

  @last_bar_hour 15
  @last_bar_minute 55

  def execute(portfolio, symbol, bars) do
    current_bar = Enum.at(bars, 0)

    opening = opening_bars(bars)
    closing = closing_bars(bars)

    position = Shiny.Portfolio.position(portfolio, symbol)

    closing? = length(closing) > 1 && current_bar.time == hd(closing).time
    opening? = length(opening) > 1 && current_bar.time == hd(opening).time

    open = Enum.at(opening, 0)
    previous_close = Enum.at(closing, 1)
    shares = trunc(portfolio.cash / current_bar.close)

    cond do
      closing? && open.open < previous_close.close && current_bar.close > open.open ->
        %Shiny.Order{
          symbol: symbol,
          shares: shares,
          type: :buy,
          limit: current_bar.close,
          time: current_bar.time
        }

      closing? && open.open > previous_close.close && current_bar.close < open.open ->
        %Shiny.Order{
          symbol: symbol,
          shares: -shares,
          type: :buy,
          limit: current_bar.close,
          time: current_bar.time
        }

      opening? && position ->
        %Shiny.Order{
          symbol: symbol,
          type: :close,
          limit: current_bar.close,
          time: current_bar.time
        }

      true ->
        nil
    end
  end

  def opening_bars(bars) do
    Enum.filter(bars, &(&1.time.hour == @first_bar_hour && &1.time.minute == @first_bar_minute))
  end

  def closing_bars(bars) do
    Enum.filter(bars, &(&1.time.hour == @last_bar_hour && &1.time.minute == @last_bar_minute))
  end
end
