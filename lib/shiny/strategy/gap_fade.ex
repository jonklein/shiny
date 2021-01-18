defmodule Shiny.Strategy.GapFade do
  @first_bar_hour 9
  @first_bar_minute 30

  @last_bar_hour 15
  @last_bar_minute 55

  def init([symbol]) do
    %{
      symbol: "SPY"
    }
  end

  def params([symbol]) do
    %{
      symbol: "SPY",
      symbols: ["SPY"],
      portfolio_value: 100_000
    }
  end

  def execute(state, portfolio, bars) do
    current_bar = Enum.at(bars[state.symbol], 0)
    opening = opening_bars(bars[state.symbol])
    closing = closing_bars(bars[state.symbol])

    closing? = length(closing) > 1 && current_bar.time == hd(closing).time
    opening? = length(opening) > 1 && current_bar.time == hd(opening).time

    open = Enum.at(opening, 0)
    previous_close = Enum.at(closing, 1)

    cond do
      closing? && open.open < previous_close.close && current_bar.close > open.open ->
        {
          state,
          %Shiny.Order{
            symbol: state.symbol,
            shares: 100,
            type: :buy
          }
        }

      closing? && open.open > previous_close.close && current_bar.close < open.open ->
        {
          state,
          %Shiny.Order{
            symbol: state.symbol,
            shares: -100,
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

  def opening_bars(bars) do
    Enum.filter(bars, &(&1.time.hour == @first_bar_hour && &1.time.minute == @first_bar_minute))
  end

  def closing_bars(bars) do
    Enum.filter(bars, &(&1.time.hour == @last_bar_hour && &1.time.minute == @last_bar_minute))
  end
end
