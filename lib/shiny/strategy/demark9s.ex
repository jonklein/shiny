defmodule Shiny.Strategy.Demark9s do
  @stop_trail 0.1

  def init([symbol]) do
    %{symbol: symbol, stop: nil, target: nil, entry: nil}
  end

  def params([symbol]) do
    %{
      symbols: [symbol],
      timeframe: "day",
      portfolio_value: 100_000
    }
  end

  def demark_higher(bars, n \\ 0)

  def demark_higher(bars = [current, _, _, _, prior | _], n) do
    if current >= prior do
      demark_higher(tl(bars), n + 1)
    else
      n
    end
  end

  def demark_higher(_, _) do
    0
  end

  def demark_lower(bars, n \\ 0)

  def demark_lower(bars = [current, _, _, _, prior | _], n) do
    if current <= prior do
      demark_lower(tl(bars), n + 1)
    else
      n
    end
  end

  def demark_lower(_, _) do
    0
  end

  def execute(state, _portfolio, bars) do
    closes = Enum.map(Map.get(bars, state.symbol), & &1.close) |> Enum.slice(0, 100)
    close = hd(closes)

    higher = demark_higher(closes)

    if higher == 9 do
      IO.inspect("9 higher at #{hd(bars[state.symbol]).time}")
    end

    lower = demark_lower(closes)

    if lower == 9 do
      IO.inspect("9 lower at #{hd(bars[state.symbol]).time}")
    end

    if state.stop do
      if close < state.stop || close > state.target do
        {%{state | stop: nil}, %Shiny.Order{type: :close, symbol: state.symbol}}
      else
        {%{state | stop: min(state.entry, max(close - @stop_trail, state.stop))}, nil}
      end
    else
      if higher >= 9 do
        {%{state | entry: close, stop: close - @stop_trail, target: close + 1.4 * @stop_trail},
         %Shiny.Order{type: :target, symbol: state.symbol, quantity: 100}}
      else
        {state, nil}
      end
    end
  end
end
