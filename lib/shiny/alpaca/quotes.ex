defmodule Shiny.Alpaca.Quotes do
  def request(symbol) do
    response = HTTPoison.get!(url(symbol))

    Jason.decode!(response.body)["results"]
    |> Enum.map(fn r ->
      %Shiny.Bar{
        open: r["o"],
        high: r["h"],
        low: r["l"],
        close: r["c"],
        volume: r["v"],
        time: DateTime.from_unix!(trunc(r["t"] / 1000.0))
      }
    end)
    |> Enum.reverse()
  end

  defp url(symbol) do
    finish = Date.to_iso8601(Date.utc_today())
    start = Date.to_iso8601(Date.add(Date.utc_today(), -3))
    api_key = System.get_env("ALPACA_API_KEY")

    "https://api.polygon.io/v2/aggs/ticker/#{symbol}/range/5/minute/#{start}/#{finish}?apiKey=#{
      api_key
    }"
  end
end
