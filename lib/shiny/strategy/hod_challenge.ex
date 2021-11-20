defmodule Shiny.Strategy.HodChallenge do
  import Shiny.Strategy.Utils
  require Logger

  def execute(state, portfolio, bars) do
    [current_bar | previous_bars] = bars[state.symbol]

    hod =
      previous_bars
      |> Enum.filter(fn i -> same_day?(current_bar.time, i.time) && market_open?(i.time) end)
      |> Enum.reverse()
      |> max_by(fn i -> Enum.max([i.close, i.open]) end)

    if hod && current_bar && market_open?(current_bar.time) do
      # IO.inspect("#{current_bar.time} - #{current_bar.close} - #{hod.close}")
    end

    position = Shiny.Portfolio.position(portfolio, state.symbol)

    hod_value = hod && Enum.max([hod.close, hod.open]) + 0.05

    cond do
      closing?(current_bar.time) ||
          (position.shares > 0 && state.trade_time &&
             DateTime.diff(current_bar.time, state.trade_time) > 60 * state.hold) ->
        {state, %Shiny.Order{symbol: state.symbol, type: :close}}

      position.shares > 0 && current_bar.close < state.stop_price ->
        Logger.info("Stop hit")
        {state, %Shiny.Order{symbol: state.symbol, type: :close}}

      position.shares > 0 &&
          current_bar.close > position.cost_basis * (1.0 + state.target / 100.0) ->
        Logger.info("Target hit")
        {state, %Shiny.Order{symbol: state.symbol, type: :close}}

      position.shares > 0 &&
          current_bar.close > position.cost_basis + 0.2 ->
        {%{state | stop_price: position.cost_basis + 0.1}, nil}

      trade_time?(current_bar.time) &&
        hod_value && current_bar && market_open?(current_bar.time) &&
        DateTime.diff(current_bar.time, hod.time) > 60 * 30 &&
        position.shares == 0 &&
          current_bar.close >= hod_value ->
        {
          %{
            state
            | trade_time: current_bar.time,
              stop_price: current_bar.close * (1.0 - state.stop / 100.0)
          },
          %Shiny.Order{
            symbol: state.symbol,
            quantity: 10000 / current_bar.close,
            type: :buy
          }
        }

      hod ->
        Logger.debug(
          "Looking for HOD of #{hod_value} at #{current_bar.time} - #{DateTime.diff(current_bar.time, hod.time)}"
        )

        {state, nil}

      true ->
        Logger.debug("Insufficient history for HOD")
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

  def closing?(d) do
    d.hour == 15 && d.minute == 55
  end
end
