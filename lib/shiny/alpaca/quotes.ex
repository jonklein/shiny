defmodule Shiny.Alpaca.Quotes do
  @moduledoc """
  Fetches market data from Polygon.  Requires the environment variables `POLYGON_API_KEY` to be set.
  """

  @doc """
  Returns a list of `%Shiny.Bar{}`
  """
  @spec request(string, string, integer) :: [%Shiny.Bar{}]
  def request(symbol, timeframe, days) do
    response = HTTPoison.get!(url(symbol, timeframe, days) |> IO.inspect())

    Jason.decode!(response.body, keys: :atoms).results
    |> Enum.map(fn r ->
      %Shiny.Bar{
        open: r.o,
        high: r.h,
        low: r.l,
        close: r.c,
        volume: r.v,
        time: DateTime.from_unix!(trunc(r.t / 1000.0)) |> DateTime.shift_zone!("America/New_York")
      }
    end)
  end

  defp url(symbol, timeframe, days) do
    finish = Date.to_iso8601(Date.utc_today())
    start = Date.to_iso8601(Date.add(Date.utc_today(), -days))
    api_key = System.get_env("POLYGON_API_KEY")
    time_fragment = url_timeframe_fragment(timeframe)

    "https://api.polygon.io/v2/aggs/ticker/#{symbol}/range/#{time_fragment}/#{start}/#{finish}?sort=asc&limit=50000&apiKey=#{
      api_key
    }"
  end

  defp url_timeframe_fragment("5m") do
    "5/minute"
  end

  defp url_timeframe_fragment("1m") do
    "1/minute"
  end

  defp url_timeframe_fragment("15m") do
    "15/minute"
  end

  defp url_timeframe_fragment("1d") do
    "1/day"
  end
end
