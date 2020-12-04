defmodule Shiny.Strategy.GapFade do
  @moduledoc false

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

    cond do
      closing? && open.open < previous_close.close && current_bar.close > open.open ->
        #        IO.inspect(
        #          "#{current_bar.time} - gap down #{previous_close.close} -> #{open.open}, close higher #{
        #            current_bar.close
        #          }"
        #        )

        shares = trunc(portfolio.cash / current_bar.close)

        %Shiny.Order{
          symbol: symbol,
          shares: shares,
          type: :buy,
          limit: current_bar.close,
          time: current_bar.time
        }

      closing? && open.open > previous_close.close && current_bar.close < open.open ->
        #        IO.inspect(
        #          "#{current_bar.time} - gap up #{previous_close.close} -> #{open.open}, close lower #{
        #            current_bar.close
        #          }"
        #        )

        shares = trunc(portfolio.cash / current_bar.close)

        %Shiny.Order{
          symbol: symbol,
          shares: -shares,
          type: :buy,
          limit: current_bar.close,
          time: current_bar.time
        }

      opening? && position ->
        #        IO.inspect("Closing position at #{current_bar.close}")

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
    Enum.filter(bars, fn b ->
      b.time.hour == @first_bar_hour && b.time.minute == @first_bar_minute
    end)
  end

  def closing_bars(bars) do
    Enum.filter(bars, fn b ->
      b.time.hour == @last_bar_hour && b.time.minute == @last_bar_minute
    end)
  end
end
