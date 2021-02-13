defmodule Shiny.Histories do
  defstruct bars: [],
            timescale: 300,
            symbol: "",
            current_bar: %Shiny.Bar{}

  def new(keys) do
    %__MODULE__{
      bars: Keyword.fetch!(keys, :bars),
      symbol: Keyword.fetch!(keys, :symbol),
      timescale: Keyword.fetch!(keys, :timescale)
    }
    |> process()
  end

  def process(history = %__MODULE__{bars: []}) do
    history
  end

  def process(history = %__MODULE__{}) do
    [first | rest] = history.bars

    if age(first) < history.timescale do
      %{history | bars: rest, current_bar: first}
    else
      history
    end
  end

  def add_quote(history = %__MODULE__{bars: [first | _]}, quote = %{bid: _, ask: _}) do
    age = age(first)

    cond do
      #      age > history.timescale * 3 ->
      #        # More than one bar behind - backfill with best guess (close of last updated bar)
      #        IO.inspect("backfilling bar for #{history.symbol} #{first.time} with close")
      #
      #        add = %Shiny.Bar{
      #          open: first.close,
      #          high: first.close,
      #          low: first.close,
      #          close: first.close,
      #          time: next_time(history, first),
      #          volume: 0
      #        }
      #
      #        add_quote(%{history | bars: [add | history.bars]}, quote)

      age > history.timescale * 2 ->
        add = %{history.current_bar | time: next_time(history, first), partial: false}

        %{
          history
          | bars: [add | history.bars],
            current_bar: %Shiny.Bar{
              open: mid(quote),
              high: mid(quote),
              low: mid(quote),
              close: mid(quote),
              time: next_time(history, first)
            }
        }

      true ->
        current_bar = %{
          history.current_bar
          | open: (history.current_bar.open == 0 && mid(quote)) || history.current_bar.open,
            high: max(history.current_bar.high, mid(quote)),
            low:
              (history.current_bar.low == 0 && mid(quote)) ||
                min(history.current_bar.low, mid(quote)),
            close: mid(quote),
            time: Shiny.Strategy.Utils.to_market_timezone(DateTime.utc_now()),
            partial: true
        }

        %{history | current_bar: current_bar}
    end
  end

  def add_quote(history = %__MODULE__{bars: []}, quote = %{last: _}) do
    first_bar = %Shiny.Bar{
      open: quote.last,
      high: quote.last,
      low: quote.last,
      close: quote.last,
      time: Shiny.Strategy.Utils.to_market_timezone(DateTime.utc_now())
    }

    %{history | bars: [first_bar]}
  end

  def add_quote(history, _) do
    history
  end

  defp mid(quote) do
    (quote.bid + quote.ask) / 2.0
  end

  defp age(bar) do
    DateTime.diff(DateTime.utc_now(), bar.time)
  end

  defp next_time(history, bar) do
    DateTime.add(bar.time, history.timescale)
  end
end
