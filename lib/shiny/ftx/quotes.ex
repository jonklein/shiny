defmodule Shiny.FTX.Quotes do
  def request(symbol, timeframe, days) do
    days = if timeframe == "1m", do: 24, else: days

    f = DateTime.utc_now()
    start = f |> DateTime.add(-60 * 60 * 24 * days)
    request(symbol, timeframe, start, f)
  end

  def request(symbol, timeframe, start, finish) do
    {:ok, %{result: result}} =
      Shiny.FTX.Request.get(
        url(
          symbol,
          resolution(timeframe),
          start |> DateTime.to_unix(),
          finish |> DateTime.to_unix()
        )
        |> IO.inspect()
      )

    Enum.map(result, fn r ->
      with {:ok, time, 0} <- DateTime.from_iso8601(r.startTime) do
        %Shiny.Bar{
          open: r.open,
          high: r.high,
          low: r.low,
          close: r.close,
          time: Shiny.Strategy.Utils.to_market_timezone(time)
        }
      end
    end)
  end

  defp url(symbol, timeframe, start, finish) do
    "/markets/#{symbol}/candles?resolution=#{timeframe}&start_time=#{start}&end_time=#{finish}"
  end

  defp resolution("15m"), do: 900
  defp resolution("5m"), do: 300
  defp resolution("1m"), do: 60
end
