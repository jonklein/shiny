defmodule Shiny.Alpaca.Client do
  # curl "https://api.polygon.io/v2/aggs/ticker/SPY/range/5/minute/2019-01-01/2019-02-01?apiKey=$ALPACA_API_KEY

  def request(path) do
    response =
      HTTPoison.get!(url(path),
        "APCA-API-KEY-ID": System.get_env("ALPACA_API_KEY"),
        "APCA-API-SECRET-KEY": System.get_env("ALPACA_API_SECRET")
      )

    Jason.decode!(response.body)
  end

  def positions() do
    request("/v2/positions")
  end

  def account() do
    request("/v2/account")
  end

  defp url(path) do
    System.get_env("ALPACA_ENDPOINT") <> path
  end
end
