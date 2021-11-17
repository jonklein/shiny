defmodule Shiny.Strategy.HodChallenge do
  import Shiny.Strategy.Utils
  import Logger

  def symbols(state) do
    [state.symbol]
  end

  def execute(state, portfolio, bars) do
    [current_bar | previous_bars] = bars[state.symbol]

    hod =
      previous_bars
      |> Enum.filter(fn i -> same_day?(current_bar.time, i.time) && market_open?(i.time) end)
      |> max_by(fn i -> i.close end)

    if hod && current_bar && market_open?(current_bar.time) do
      # IO.inspect("#{current_bar.time} - #{current_bar.close} - #{hod.close}")
    end

    position = Shiny.Portfolio.position(portfolio, state.symbol)

    trail = 1000.3

    cond do
      closing?(current_bar.time) ||
          (position.shares > 0 && state.open_time &&
             DateTime.diff(current_bar.time, state.open_time) > 60 * state.hold) ->
        {state, %Shiny.Order{symbol: state.symbol, type: :close}}

      position.shares > 0 &&
          (current_bar.close > position.cost_basis * (1.0 + state.target / 100.0) ||
             current_bar.close < position.cost_basis * (1.0 - state.stop / 100.0)) ->
        {state, %Shiny.Order{symbol: state.symbol, type: :close}}

      hod && current_bar && market_open?(current_bar.time) && trade_time?(current_bar.time) &&
        DateTime.diff(current_bar.time, hod.time) > 60 * 30 &&
        position.shares == 0 &&
        current_bar.close - current_bar.open > 0.02 &&
          current_bar.close > hod.close + 0.01 ->
        {
          %{state | open_time: current_bar.time},
          %Shiny.Order{
            symbol: state.symbol,
            quantity: 10000 / current_bar.close,
            type: :buy
          }
        }

      hod ->
        # Logger.info("Looking for HOD of #{hod.close} at #{current_bar.time}")
        {state, nil}

      true ->
        # Logger.info("Insufficient history for HOD")
        {state, nil}
    end
  end

  defp max_by([], _) do
  end

  defp max_by(a, b) do
    Enum.max_by(a, b)
  end

  defp trade_time?(d) do
    t = d.hour * 60 + d.minute
    t >= 10 * 60 + 30
  end

  #  defp market_open?(d) do
  #    t = d.hour * 60 + d.minute
  #    t < 16 * 60 && t >= 9 * 60 + 30
  #  end

  def closing?(d) do
    d.hour == 15 && d.minute == 55
  end
end