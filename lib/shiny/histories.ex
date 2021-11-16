defmodule Shiny.Histories do
  defstruct bars: [],
            timescale: 300,
            symbol: ""

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
      %{history | bars: [%{first | partial: true} | rest]}
    else
      history
    end
  end

  def add_quote(history = %__MODULE__{bars: [first | rest]}, quote = %{bid: _, ask: _}) do
    age = age(first)

    cond do
      age > history.timescale * 2 ->
        [first | rest] = history.bars
        first = %{first | time: next_time(history, hd(rest)), partial: false}

        add = %Shiny.Bar{
          open: mid(quote),
          high: mid(quote),
          low: mid(quote),
          close: mid(quote),
          partial: true,
          time: Shiny.Strategy.Utils.to_market_timezone(DateTime.utc_now())
        }

        %{history | bars: [add, first | rest]}

      true ->
        first = %{
          first
          | open: (first.open == 0 && mid(quote)) || first.open,
            high: max(first.high, mid(quote)),
            low:
              (first.low == 0 && mid(quote)) ||
                min(first.low, mid(quote)),
            close: mid(quote),
            time: Shiny.Strategy.Utils.to_market_timezone(DateTime.utc_now()),
            partial: true
        }

        %{history | bars: [first | rest]}
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
