defmodule Shiny.Tradier.Quotes do
  def request(symbol, timeframe, days) do
    days = if timeframe == "1m", do: 24, else: days

    f = NaiveDateTime.utc_now()
    start = f |> NaiveDateTime.add(-60 * 60 * 24 * days)
    request(symbol, timeframe, start, f)
  end

  def request(symbol, timeframe, start, finish) do
    with {:ok, data} <-
           Shiny.Tradier.get(url(symbol, timeframe, start, finish))
           |> parse_response() do
      bars =
        data
        |> Enum.reverse()
        |> Enum.map(fn d ->
          {:ok, t} = DateTime.from_unix(d.timestamp)

          %Shiny.Bar{
            open: d.open,
            high: d.high,
            low: d.low,
            close: d.close,
            volume: d.volume,
            time: Shiny.Strategy.Utils.to_market_timezone(t)
          }
        end)

      Shiny.Histories.new(bars: bars, timescale: timeframe, symbol: symbol)
      bars |> Enum.reverse()
    else
      _ ->
        nil
    end
  end

  defp url(symbol, timeframe, start, finish) when timeframe in ["1m", "5m", "15m"] do
    ts = format_date(start)
    tf = format_date(finish)

    "/v1/markets/timesales?symbol=#{symbol}&interval=#{interval_fragment(timeframe)}&start=#{ts}&end=#{tf}"
  end

  defp url(symbol, timeframe, start, finish) when timeframe > 900 do
    ts = format_date(start)
    tf = format_date(finish)

    "/v1/markets/history?symbol=#{symbol}&interval=#{interval_fragment(timeframe)}&start=#{ts}&end=#{tf}"
  end

  defp parse_response({:ok, %{series: %{data: data = %{}}}}) do
    {:ok, [data]}
  end

  defp parse_response({:ok, %{series: %{data: data}}}) do
    {:ok, data}
  end

  defp parse_response({:ok, %{series: nil}}) do
    {:ok, []}
  end

  defp parse_response({:error, err}) do
    {:error, err}
  end

  defp format_date(date) do
    ny_date = Timex.Timezone.convert(date, "America/New_York")
    {:ok, d} = Timex.format(ny_date, "%Y-%m-%d+%H:%M:%S", :strftime)
    URI.encode(d)
  end

  defp interval_fragment("1m") do
    "1min"
  end

  defp interval_fragment("5m") do
    "5min"
  end

  defp interval_fragment("15m") do
    "15min"
  end

  defp interval_fragment("1h") do
    "1h"
  end

  defp interval_fragment("1d") do
    "1d"
  end
end
