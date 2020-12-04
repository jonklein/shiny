defmodule Shiny.Alpaca.Quotes do
  @moduledoc """
  Fetches market data from Alpaca (or partner Polygon).  Requires the environment variables `ALPACA_API_KEY` and `ALPACA_API_SECRET` to be set.
  """

  @doc """
    Returns a list of `%Shiny.Bar{}`
  """
  def request(symbol, days) do
    response = HTTPoison.get!(url(symbol, days))

    Jason.decode!(response.body)["results"]
    |> Enum.map(fn r ->
      %Shiny.Bar{
        open: r["o"],
        high: r["h"],
        low: r["l"],
        close: r["c"],
        volume: r["v"],
        time:
          DateTime.from_unix!(trunc(r["t"] / 1000.0)) |> DateTime.shift_zone!("America/New_York")
      }
    end)
  end

  defp url(symbol, days) do
    finish = Date.to_iso8601(Date.utc_today())
    start = Date.to_iso8601(Date.add(Date.utc_today(), -days))
    api_key = System.get_env("ALPACA_API_KEY")

    "https://api.polygon.io/v2/aggs/ticker/#{symbol}/range/5/minute/#{start}/#{finish}?sort=asc&limit=50000&apiKey=#{
      api_key
    }"
  end
end
